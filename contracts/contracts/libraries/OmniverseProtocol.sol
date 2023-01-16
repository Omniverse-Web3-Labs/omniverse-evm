// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../OmniverseTransactionData.sol";

enum VerifyResult {
    Success,
    Malicious
}
    
struct OmniverseTx {
    OmniverseTransactionData txData;
    uint256 timestamp;
}

struct EvilTxData {
    OmniverseTx txData;
    uint256 hisNonce;
}

struct RecordedCertificate {
    OmniverseTx[] txList;
    EvilTxData[] evilTxList;
}

library OmniverseProtocol {
    /**
     * @dev Get the hash of a transaction
     */
    function getTransactionHash(OmniverseTransactionData memory _data) public pure returns (bytes32) {
        bytes memory rawData = abi.encodePacked(uint128(_data.nonce), _data.chainId, _data.initiator, _data.from, _data.op, _data.data, uint128(_data.amount));
        return keccak256(rawData);
    }

    /**
     * @dev Recover the address
     */
    function recoverAddress(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := mload(add(_signature, 65))
        }
        address recovered = ecrecover(_hash, v, r, s);
        require(recovered != address(0), "Verify failed");
        return recovered;
    }

    /**
     * @dev Check if the public key matches the recovered address
     */
    function checkPkMatched(bytes memory _pk, address _address) public pure {
        bytes32 hash = keccak256(_pk);
        address pkAddress = address(uint160(uint256(hash)));
        require(_address == pkAddress, "Signer not sender");
    }

    /**
     * @dev Verify an omniverse transaction
     */
    function verifyTransaction(RecordedCertificate storage rc, OmniverseTransactionData memory _data) public returns (VerifyResult) {
        uint256 nonce = rc.txList.length;
        
        bytes32 txHash = getTransactionHash(_data);
        address recoveredAddress = recoverAddress(txHash, _data.signature);
        // Signature verified failed
        checkPkMatched(_data.from, recoveredAddress);

        // Check nonce
        if (nonce == _data.nonce) {
            return VerifyResult.Success;
        }
        else if (nonce > _data.nonce) {
            // The message has been received, check conflicts
            OmniverseTx storage hisTx = rc.txList[_data.nonce];
            bytes32 hisTxHash = getTransactionHash(hisTx.txData);
            if (hisTxHash != txHash) {
                // to be continued, add to evil list, but can not be duplicated
                EvilTxData storage evilTx = rc.evilTxList.push();
                evilTx.hisNonce = nonce;
                evilTx.txData.txData = _data;
                evilTx.txData.timestamp = block.timestamp;
                return VerifyResult.Malicious;
            }
            else {
                revert("Duplicated");
            }
        }
        else {
            revert("Nonce error");
        }
    }
}