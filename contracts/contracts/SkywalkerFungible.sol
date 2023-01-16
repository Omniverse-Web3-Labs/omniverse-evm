// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20.sol";
import "./libraries/OmniverseProtocol.sol";
import "./interfaces/IOmniverseFungible.sol";

contract SkywalkerFungible is ERC20, Ownable, IOmniverseFungible {
    uint8 constant DEPOSIT = 0;
    uint8 constant TRANSFER = 1;
    uint8 constant WITHDRAW = 2;
    uint8 constant MINT = 3;

    struct DepositRequest {
        bytes receiver;
        uint256 amount;
    }

    struct DelayedTx {
        bytes sender;
        uint256 nonce;
    }

    struct Member {
        uint32 chainId;
        bytes contractAddr;
    }

    uint32 chainId;
    uint256 public cdTime;
    mapping(bytes => RecordedCertificate) transactionRecorder;
    mapping(bytes => OmniverseTx) public transactionCache;

    Member[] members;
    mapping(bytes => uint256) omniverseBalances;
    DelayedTx[] delayedTxs;
    bytes public committee;
    DepositRequest[] depositRequests;
    uint256 public depositDealingIndex;
    mapping(address => bytes) accountsMap;

    event OmniverseTokenTransfer(bytes from, bytes to, uint256 value);
    event OmniverseTokenWithdraw(bytes from, uint256 value);
    event OmniverseTokenDeposit(bytes to, uint256 value);
    event OmniverseTokenWrongOp(bytes sender, uint8 op);
    event TransactionSent(bytes pk, uint256 nonce);

    /**
     * @dev Throws if called by any account other than the committe
     */
    modifier onlyCommittee() {
        address committeeAddr = _pkToAddress(committee);
        require(msg.sender == committeeAddr, "Not committee");
        _;
    }

    /**
     * @dev Initiates the contract
     * @param _chainId The chain which the contract is deployed on
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     */
    constructor(uint8 _chainId, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        chainId = _chainId;
    }

    /**
     * @dev Set the address of committee
     */
    function setCommitteeAddress(bytes calldata _address) public onlyOwner {
        committee = _address;
    }

    /**
     * @dev See {IOmniverseFungible-sendOmniverseTransaction}
     * Send an omniverse transaction
     */
    function sendOmniverseTransaction(OmniverseTransactionData calldata _data) external override {
        _omniverseTransaction(_data);
    }

    /**
     * @dev Trigger the execution of the first delayed transaction
     */
    function triggerExecution() external {
        require(delayedTxs.length > 0, "No delayed tx");

        OmniverseTx storage cache = transactionCache[delayedTxs[0].sender];
        require(cache.timestamp != 0, "Not cached");
        require(cache.txData.nonce == delayedTxs[0].nonce, "Nonce error");
        (OmniverseTransactionData storage txData, uint256 timestamp) = (cache.txData, cache.timestamp);
        require(block.timestamp >= timestamp + cdTime, "Not executable");
        delayedTxs[0] = delayedTxs[delayedTxs.length - 1];
        delayedTxs.pop();
        cache.timestamp = 0;
        // Add to transaction recorder
        RecordedCertificate storage rc = transactionRecorder[txData.from];
        rc.txList.push(cache);
        if (txData.chainId == chainId) {
            emit TransactionSent(txData.from, txData.nonce);
        }

        uint8 op = txData.op;
        if (op == WITHDRAW) {
            _omniverseWithdraw(txData.from, txData.amount, txData.chainId == chainId);
        }
        else if (op == TRANSFER) {
            _omniverseTransfer(txData.from, txData.data, txData.amount);
        }
        else if (op == DEPOSIT) {
            _omniverseDeposit(txData.from, txData.data, txData.amount);
        }
        else if (op == MINT) {
            _checkOwner(txData.from);
            _omniverseMint(txData.data, txData.amount);
        }
        else {
            emit OmniverseTokenWrongOp(txData.from, op);
        }
    }
    
    /**
     * @dev Check if the transaction can be executed successfully
     */
    function _checkExecution(OmniverseTransactionData memory txData) internal view {
        uint8 op = txData.op;
        if (op == WITHDRAW) {
            _checkOmniverseWithdraw(txData.from, txData.amount);
        }
        else if (op == TRANSFER) {
            _checkOmniverseTransfer(txData.from, txData.amount);
        }
        else if (op == DEPOSIT) {
        }
        else if (op == MINT) {
            _checkOwner(txData.from);
        }
        else {
            revert("OP code error");
        }
    }

    /**
     * @dev Returns the nearest exexutable delayed transaction info
     * or returns default if not found
     */
    function getExecutableDelayedTx() external view returns (DelayedTx memory ret) {
        if (delayedTxs.length > 0) {
            OmniverseTx storage cache = transactionCache[delayedTxs[0].sender];
            if (block.timestamp >= cache.timestamp + cdTime) {
                ret = delayedTxs[0];
            }
        }
    }

    /**
     * @dev Returns the count of delayed transactions
     */
    function getDelayedTxCount() external view returns (uint256) {
        return delayedTxs.length;
    }

    /**
     * @dev See {IOmniverseFungible-omniverseBalanceOf}
     * Returns the omniverse balance of a user
     */
    function omniverseBalanceOf(bytes calldata _pk) external view override returns (uint256) {
        return omniverseBalances[_pk];
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        bytes storage pk = accountsMap[account];
        if (pk.length == 0) {
            return 0;
        }
        else {
            return omniverseBalances[pk];
        }
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function nativeBalanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Receive and check an omniverse transaction
     */
    function _omniverseTransaction(OmniverseTransactionData memory _data) internal {
        // Check if the tx initiator is correct
        bool found = false;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i].chainId == _data.chainId) {
                require(keccak256(members[i].contractAddr) == keccak256(_data.initiator), "Wrong initiator");
                found = true;
            }
        }
        require(found, "Wrong initiator");

        // Check if the sender is honest
        // to be continued, we can use block list instead of `isMalicious`
        require(!isMalicious(_data.from), "User malicious");

        // Verify the signature
        VerifyResult verifyRet = OmniverseProtocol.verifyTransaction(transactionRecorder[_data.from], _data);

        if (verifyRet == VerifyResult.Success) {
            // Check cache
            OmniverseTx storage cache = transactionCache[_data.from];
            require(cache.timestamp == 0, "Transaction cached");
            // Logic verification
            _checkExecution(_data);
            // Delays in executing
            cache.txData = _data;
            cache.timestamp = block.timestamp;
            delayedTxs.push(DelayedTx(_data.from, _data.nonce));
        }
        else if (verifyRet == VerifyResult.Malicious) {
            // Slash
        }
    }

    /**
     * @dev Check if an omniverse transfer operation can be executed successfully
     */
    function _checkOmniverseTransfer(bytes memory _from, uint256 _amount) internal view {
        uint256 fromBalance = omniverseBalances[_from];
        require(fromBalance >= _amount, "Exceed Balance");
    }

    /**
     * @dev Exucute an omniverse transfer operation
     */
    function _omniverseTransfer(bytes memory _from, bytes memory _to, uint256 _amount) internal {
        _checkOmniverseTransfer(_from, _amount);
        
        uint256 fromBalance = omniverseBalances[_from];
        
        unchecked {
            omniverseBalances[_from] = fromBalance - _amount;
        }
        omniverseBalances[_to] += _amount;

        emit OmniverseTokenTransfer(_from, _to, _amount);

        address toAddr = _pkToAddress(_to);
        accountsMap[toAddr] = _to;
    }

    /**
     * @dev Check if an omniverse withdraw operation can be executed successfully
     */
    function _checkOmniverseWithdraw(bytes memory _from, uint256 _amount) internal view {
        uint256 fromBalance = omniverseBalances[_from];
        require(fromBalance >= _amount, "Exceed Balance");
    }

    /**
     * @dev Execute an omniverse withdraw operation
     */
    function _omniverseWithdraw(bytes memory _from, uint256 _amount, bool _thisChain) internal {
        _checkOmniverseWithdraw(_from, _amount);

        uint256 fromBalance = omniverseBalances[_from];
        
        unchecked {
            omniverseBalances[_from] = fromBalance - _amount;
        }
        
        if (_thisChain) {
            address ownerAddr = _pkToAddress(_from);

            // mint
            _totalSupply += _amount;
            _balances[ownerAddr] += _amount;
        }

        emit OmniverseTokenWithdraw(_from, _amount);
    }

    /**
     * @dev Execute an omniverse deposit operation
     */
    function _omniverseDeposit(bytes memory _from, bytes memory _to, uint256 _amount) internal {
        require(keccak256(_from) == keccak256(committee), "Not committee");

        unchecked {
            omniverseBalances[_to] += _amount;
        }

        emit OmniverseTokenDeposit(_to, _amount);
    }
    
    /**
     * @dev Check if the public key is the owner
     */
    function _checkOwner(bytes memory _pk) internal view {
        address fromAddr = _pkToAddress(_pk);
        require(fromAddr == owner(), "Not owner");
    }

    /**
     * @dev Execute an omniverse mint operation
     */
    function _omniverseMint(bytes memory _to, uint256 _amount) internal {
        omniverseBalances[_to] += _amount;
        emit OmniverseTokenTransfer("", _to, _amount);

        address toAddr = _pkToAddress(_to);
        accountsMap[toAddr] = _to;
    }

    /**
     * @dev Convert the public key to evm address
     */
    function _pkToAddress(bytes memory _pk) internal pure returns (address) {
        bytes32 hash = keccak256(_pk);
        return address(uint160(uint256(hash)));
    }

    /**
     * @dev Add new chain members to the token
     */
    function setMembers(Member[] calldata _members) external onlyOwner {
        for (uint256 i = 0; i < _members.length; i++) {
            if (i < members.length) {
                members[i] = _members[i];
            }
            else {
                members.push(_members[i]);
            }
        }

        for (uint256 i = _members.length; i < members.length; i++) {
            delete members[i];
        }
    }

    /**
     * @dev Returns chain members of the token
     */
    function getMembers() external view returns (Member[] memory) {
        return members;
    }

    /**
     * @dev Users request to convert native token to omniverse token
     */
    function requestDeposit(bytes calldata from, uint256 amount) external {
        address fromAddr = _pkToAddress(from);
        require(fromAddr == msg.sender, "Signer not sender");

        uint256 fromBalance = _balances[fromAddr];
        require(fromBalance >= amount, "Exceed balance");

        // Update
        unchecked {
            _balances[fromAddr] = fromBalance - amount;
        }
        _totalSupply -= amount;

        depositRequests.push(DepositRequest(from, amount));
    }

    /**
     * @dev The committee approves a user's request
     */
    function approveDeposit(uint256 index, uint256 nonce, bytes calldata signature) external onlyCommittee {
        require(index == depositDealingIndex, "Index error");

        DepositRequest storage request = depositRequests[index];
        depositDealingIndex++;

        OmniverseTransactionData memory p;
        p.nonce = nonce;
        p.chainId = chainId;
        p.from = committee;
        p.initiator = abi.encodePacked(address(this));
        p.signature = signature;
        p.op = DEPOSIT;
        p.data = request.receiver;
        p.amount = request.amount;
        _omniverseTransaction(p);
    }

    /**
     @dev Returns the deposit request at `index`
     @param index: The index of requests
     */
    function getDepositRequest(uint256 index) external view returns (DepositRequest memory ret) {
        if (depositRequests.length > index) {
            ret = depositRequests[index];
        }
    }
    
    /**
     @dev See {IERC20-decimals}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    /**
     * @dev See IOmniverseFungible
     */
    function getTransactionCount(bytes memory _pk) external override view returns (uint256) {
        return transactionRecorder[_pk].txList.length;
    }

    /**
     * @dev See IOmniverseFungible
     */
    function getTransactionData(bytes calldata _user, uint256 _nonce) external override view returns (OmniverseTransactionData memory txData, uint256 timestamp) {
        RecordedCertificate storage rc = transactionRecorder[_user];
        OmniverseTx storage omniTx = rc.txList[_nonce];
        txData = omniTx.txData;
        timestamp = omniTx.timestamp;
    }

    /**
     * @dev Set the cooling down time of an omniverse transaction
     */
    function setCooingDownTime(uint256 _time) external {
        cdTime = _time;
    }

    /**
     * @dev Index the user is malicious or not
     */
    function isMalicious(bytes memory _pk) public view returns (bool) {
        RecordedCertificate storage rc = transactionRecorder[_pk];
        return (rc.evilTxList.length > 0);
    }

    /**
     * @dev See IOmniverseFungible
     */
    function getChainId() external view returns (uint32) {
        return chainId;
    }
}