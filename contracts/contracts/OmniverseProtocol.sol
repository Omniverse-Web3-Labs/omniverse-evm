// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IOmniverseProtocol.sol";

contract OmniverseProtocol is IOmniverseProtocol {
    struct OmniverseTx {
        OmniverseTokenProtocol txData;
        uint256 timestamp;
    }

    struct EvilTxData {
        OmniverseTx txData;
        uint256 hisNonce;
    }

    struct RecordedCertificate {
        // uint256 nonce;
        // address evmAddress;
        OmniverseTx[] txList;
        EvilTxData[] evilTxList;
    }

    uint8 private chainId;
    uint256 public cdTime;
    mapping(bytes => RecordedCertificate) transactionRecorder;

    constructor(uint8 _chainId) {
        chainId = _chainId;
    }

    /**
     * @dev See IOmniverseProtocl
     */
    function verifyTransaction(OmniverseTokenProtocol calldata _data) external override returns (VerifyResult) {
        RecordedCertificate storage rc = transactionRecorder[_data.from];
        uint256 nonce = transactionRecorder[_data.from].txList.length;
        
        bytes32 txHash = _getTransactionHash(_data);
        address recoveredAddress = _recoverAddress(txHash, _data.signature);
        // Signature verified failed
        _checkPkMatched(_data.from, recoveredAddress);

        // Check nonce
        if (nonce == _data.nonce) {
            uint256 lastestTxTime = 0;
            if (rc.txList.length > 0) {
                lastestTxTime = rc.txList[rc.txList.length - 1].timestamp;
            }
            require(block.timestamp >= lastestTxTime + cdTime, "Transaction cooling down");
            // Add to transaction recorder
            OmniverseTx storage omniTx = rc.txList.push();
            omniTx.timestamp = block.timestamp;
            omniTx.txData = _data;
            if (_data.chainId == chainId) {
                emit TransactionSent(_data.from, _data.nonce);
            }
        }
        else if (nonce > _data.nonce) {
            // The message has been received, check conflicts
            OmniverseTx storage hisTx = rc.txList[_data.nonce];
            bytes32 hisTxHash = _getTransactionHash(hisTx.txData);
            if (hisTxHash != txHash) {
                // to be continued, add to evil list, but can not be duplicated
                EvilTxData storage evilTx = rc.evilTxList.push();
                evilTx.hisNonce = nonce;
                evilTx.txData.txData = _data;
                evilTx.txData.timestamp = block.timestamp;
                return VerifyResult.Malicious;
            }
            else {
                revert("Transaction duplicated");
            }
        }
        else {
            revert("Nonce error");
        }
        return VerifyResult.Success;
    }

    /**
     * @dev See IOmniverseProtocl
     */
    function getTransactionCount(bytes memory _pk) external view override returns (uint256) {
        return transactionRecorder[_pk].txList.length;
    }

    /**
     * @dev Returns the transaction data of the user with a specified nonce
     */
    function getTransactionData(bytes calldata _user, uint256 _nonce) external view override returns (OmniverseTokenProtocol memory txData, uint256 timestamp) {
        RecordedCertificate storage rc = transactionRecorder[_user];
        OmniverseTx storage omniTx = rc.txList[_nonce];
        txData = omniTx.txData;
        timestamp = omniTx.timestamp;
    }

    /**
     *
     */
    function getCoolingDownTime() external view override returns (uint256) {
        return cdTime;
    }

    function setCooingDownTime(uint256 _time) external {
        cdTime = _time;
    }

    /**
     * @dev Returns the chain ID
     */
    function getChainId() external view override returns (uint8) {
        return chainId;
    }

    /**
     * @dev Get the hash of a tx
     */
    function _getTransactionHash(OmniverseTokenProtocol memory _data) internal pure returns (bytes32) {
        bytes memory bData;
        for (uint256 i = 0; i < _data.data.items.length; i++) {
            bData = bytes.concat(bData, _getPayloadItemRawData(_data.data.items[i]));
        }
        bytes memory rawData = abi.encodePacked(uint128(_data.nonce), _data.chainId, _data.from, _data.to, bData);
        return keccak256(rawData);
    }

    function getRawData(OmniverseTokenProtocol memory _data) external pure returns (bytes memory) {
        bytes memory bData;
        for (uint256 i = 0; i < _data.data.items.length; i++) {
            bData = bytes.concat(bData, _getPayloadItemRawData(_data.data.items[i]));
        }
        bytes memory rawData = abi.encodePacked(uint128(_data.nonce), _data.chainId, _data.from, _data.to, bData);
        return rawData;
    }

    function _getPayloadItemRawData(PayloadItem memory item) public pure returns (bytes memory ret) {
        if (item.msgType == MsgType.EvmString) {
            (string memory r) = abi.decode(item.value, (string));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmU8) {
            (uint8 r) = abi.decode(item.value, (uint8));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmU16) {
            (uint16 r) = abi.decode(item.value, (uint16));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmU32) {
            (uint32 r) = abi.decode(item.value, (uint32));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmU64) {
            (uint64 r) = abi.decode(item.value, (uint64));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmU128) {
            (uint128 r) = abi.decode(item.value, (uint128));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmI8) {
            (int8 r) = abi.decode(item.value, (int8));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmI16) {
            (int16 r) = abi.decode(item.value, (int16));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmI32) {
            (int32 r) = abi.decode(item.value, (int32));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmI64) {
            (int64 r) = abi.decode(item.value, (int64));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmI128) {
            (int128 r) = abi.decode(item.value, (int128));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmStringArray) {
            (string[] memory r) = abi.decode(item.value, (string[]));
            bytes memory sb;
            for (uint256 i = 0; i < r.length; i++) {
                sb = bytes.concat(sb, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, sb);
        }
        else if (item.msgType == MsgType.Bytes) {
            (bytes memory r) = abi.decode(item.value, (bytes));
            ret = abi.encodePacked(item.name, r);
        }
        else if (item.msgType == MsgType.EvmU16Array) {
            (uint16[] memory r) = abi.decode(item.value, (uint16[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
        else if (item.msgType == MsgType.EvmU32Array) {
            (uint32[] memory r) = abi.decode(item.value, (uint32[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
        else if (item.msgType == MsgType.EvmU64Array) {
            (uint64[] memory r) = abi.decode(item.value, (uint64[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
        else if (item.msgType == MsgType.EvmU128Array) {
            (uint128[] memory r) = abi.decode(item.value, (uint128[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
        else if (item.msgType == MsgType.EvmI8Array) {
            (int8[] memory r) = abi.decode(item.value, (int8[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
        else if (item.msgType == MsgType.EvmI16Array) {
            (int16[] memory r) = abi.decode(item.value, (int16[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
        else if (item.msgType == MsgType.EvmI32Array) {
            (int32[] memory r) = abi.decode(item.value, (int32[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
        else if (item.msgType == MsgType.EvmI64Array) {
            (int64[] memory r) = abi.decode(item.value, (int64[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
        else if (item.msgType == MsgType.EvmI128Array) {
            (int128[] memory r) = abi.decode(item.value, (int128[]));
            
            bytes memory b;
            for (uint256 i = 0; i < r.length; i++) {
                b = bytes.concat(b, abi.encodePacked(r[i]));
            }
            ret = abi.encodePacked(item.name, b);
        }
    }

    /**
     * @dev Recover the address
     */
    function _recoverAddress(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := mload(add(_signature, 65))
        }
        address recovered = ecrecover(_hash, v, r, s);
        require(recovered != address(0), "Signature verifying failed");
        return recovered;
    }

    /**
     * @dev Check if the public key matches the recovered address
     */
    function _checkPkMatched(bytes memory _pk, address _address) internal pure {
        bytes32 hash = keccak256(_pk);
        address pkAddress = address(uint160(uint256(hash)));
        require(_address == pkAddress, "Sender not signer");
    }

    /**
     * @dev See IOmniverseProtocl
     */
    function isMalicious(bytes memory _pk) external view override returns (bool) {
        RecordedCertificate storage rc = transactionRecorder[_pk];
        return (rc.evilTxList.length > 0);
    }
}