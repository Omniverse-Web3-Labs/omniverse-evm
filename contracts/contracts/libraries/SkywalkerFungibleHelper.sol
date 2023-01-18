// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../OmniverseTransactionData.sol";

/**
 * @notice Fungible token data structure, which will be encoded from or decoded from
 * the field `payload` of `OmniverseTransactionData`
 *
 * op: The operation type
 * NOTE op: 0-31 are reserved values, 32-255 are custom values
 *             op: 0 Transfers omniverse token `amount` from user `from` to user `exData`, `from` MUST have at least `amount` token
 *             op: 1 User `from` mints token `amount` to user `exData`
 *             op: 2 User `from` burns token `amount` from user `exData`
 * exData: The operation data. This sector could be empty and is determined by `op`
 * amount: The amount of token which is operated
 */
struct Fungible {
    uint8 op;
    bytes exData;
    uint256 amount;
}

/**
 * @notice Used to record one omniverse transaction data
 * txData: The original omniverse transaction data committed to the contract
 * timestamp: When the omniverse transaction data is committed
 */
struct OmniverseTx {
    OmniverseTransactionData txData;
    uint256 timestamp;
}

/**
 * @notice An malicious omniverse transaction data
 * oData: The recorded omniverse transaction data
 * hisNonce: The nonce of the historical transaction which it conflicts with
 */
struct EvilTxData {
    OmniverseTx oData;
    uint256 hisNonce;
}

/**
 * @notice Used to record the historical omniverse transactions of a user
 * txList: Successful historical omniverse transaction list
 * evilTxList: Malicious historical omniverse transaction list
 */
struct RecordedCertificate {
    OmniverseTx[] txList;
    EvilTxData[] evilTxList;
}

// Result of verification of an omniverse transaction
enum VerifyResult {
    Success,
    Malicious
}

/**
 * @notice The library is mainly responsible for omniverse transaction verification and
 * provides some basic methods.
 * NOTE The verification method is for reference only, and developers can design appropriate
 * verification mechanism based on their bussiness logic.
 */
library SkywalkerFungibleHelper {
    /**
     * @notice Encode `_fungible` into bytes
     */
    function encodeData(Fungible memory _fungible) internal pure returns (bytes memory) {
        return abi.encode(_fungible.op, _fungible.exData, _fungible.amount);
    }

    /**
     * @notice Decode `_data` from bytes to Fungible
     */
    function decodeData(bytes memory _data) internal pure returns (Fungible memory) {
        (uint8 op, bytes memory exData, uint256 amount) = abi.decode(_data, (uint8, bytes, uint256));
        return Fungible(op, exData, amount);
    }
    
    /**
     * @notice Get the hash of a transaction
     */
    function getTransactionHash(OmniverseTransactionData memory _data) public pure returns (bytes32) {
        Fungible memory fungible = decodeData(_data.payload);
        bytes memory payload = abi.encodePacked(fungible.op, fungible.exData, uint128(fungible.amount));
        bytes memory rawData = abi.encodePacked(_data.nonce, _data.chainId, _data.initiateSC, _data.from, payload);
        return keccak256(rawData);
    }

    /**
     * @notice Recover the address
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
     * @notice Check if the public key matches the recovered address
     */
    function checkPkMatched(bytes memory _pk, address _address) public pure {
        bytes32 hash = keccak256(_pk);
        address pkAddress = address(uint160(uint256(hash)));
        require(_address == pkAddress, "Signer not sender");
    }

    /**
     * @notice Verify an omniverse transaction
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
                evilTx.oData.txData = _data;
                evilTx.oData.timestamp = block.timestamp;
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