// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Omniverse transaction data structure, different `op` indicates different type of omniverse transaction
 * nonce: The number of o-transactions sent from a user
 * chainId: The chain where the o-transaction is initiated
 * initiator: The contract address from which the o-transaction is initiated
 * from: The Omniverse account which signs the o-transaction
 * op: The operation type
 * data: The operation data
 * tokenId: the token id
 * signature: The signature of the above informations
 * 
 * NOTE op: 0-31 are reserved values, 32-255 are custom values
 * 
 * op: 0 Transfers omniverse token `tokenId` from user `from` to user `data`, the token `tokenId` MUST be owned by `from`
 * op: 1 User `from` mints token `tokenId` to user `data`
 * op: 2 User `from` burns token `tokenId` from user `data`
 */
struct OmniverseTransactionData {
    uint256 nonce;
    uint32 chainId;
    bytes initiator;
    bytes from;
    uint8 op;
    bytes data;
    uint256 tokenId;
    bytes signature;
}