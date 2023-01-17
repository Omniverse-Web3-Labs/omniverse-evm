// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Omniverse transaction data structure, different `op` indicates different type of omniverse transaction
 * @Member nonce: The serial number of an o-transactions sent from an Omniverse Account. If the current nonce of an o-account is k, the valid nonce in the next o-transaction is k+1. 
 * @Member chainId: The chain where the o-transaction is initiated
 * @Member initiate_sc: The contract address from which the o-transaction is first initiated
 * @Member from: The Omniverse account which signs the o-transaction
 * @Member op: The operation type. NOTE op: 0-31 are reserved values, 32-255 are custom values
 *             op: 0 Transfers omniverse token `token_info` from user `from` to user `data`, `from` MUST have at least `amount` token
 *             op: 1 User `from` mints token `token_info` to user `data`
 *             op: 2 User `from` burns token `token_info` from user `data`
 * @Member ex_data: The operation data. This sector could be empty and is determined by `op`
 * @Member token_info: The amount of token which is operated
 * 
 * @Member signature: The signature of the above informations. 
 *                    Firstly, the above sectors are combined as 
 *                    `bytes memory rawData = abi.encodePacked(_.nonce, .chainId, .initiator, .from, .op, .ex_data, uint128(_data.token_info));`
 *                    The it is hashed by `keccak256(rawData)`
 *                    The signature is to the hashed value.
 * 
 */
struct OmniverseTransactionData {
    uint128 nonce;
    uint32 chainId;
    bytes initiate_sc;
    bytes from;
    uint8 op;
    bytes ex_data;
    uint256 token_info;
    bytes signature;
}