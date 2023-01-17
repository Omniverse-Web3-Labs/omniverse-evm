// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Omniverse transaction data structure, different `op` indicates different type of omniverse transaction
 * @Member nonce: The serial number of an o-transactions sent from an Omniverse Account. If the current nonce of an o-account is k, the valid nonce in the next o-transaction is k+1. 
 * @Member chainId: The chain where the o-transaction is initiated
 * @Member initiator: The contract address from which the o-transaction is initiated
 * @Member from: The Omniverse account which signs the o-transaction
 * @Member op: The operation type. NOTE op: 0-31 are reserved values, 32-255 are custom values
 *             op: 0 Transfers omniverse token `amount` from user `from` to user `data`, `from` MUST have at least `amount` token
 *             op: 1 User `from` mints token `amount` to user `data`
 *             op: 2 User `from` burns token `amount` from user `data`
 * @Member data: The operation data. This sector could be empty and is determined by `op`
 * @Member amount: The amount of token which is operated
 * 
 * @Member signature: The signature of the above informations. 
 *                    Firstly, the above sectors are combined as 
 *                    `bytes memory rawData = abi.encodePacked(uint128(_data.nonce), _data.chainId, _data.initiator, _data.from, _data.op, _data.data, uint128(_data.amount));`
 *                    The it is hashed by `keccak256(rawData)`
 *                    The signature is to the hashed value.
 * 
 */
struct OmniverseTransactionData {
    uint256 nonce;
    uint32 chainId;
    bytes initiator;
    bytes from;
    uint8 op;
    bytes data;
    uint256 amount;
    bytes signature;
}