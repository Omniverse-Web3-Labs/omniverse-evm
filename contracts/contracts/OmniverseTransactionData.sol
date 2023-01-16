// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct OmniverseTransactionData {
    uint256 nonce;      // The number of o-transactions sent from a user
    uint32 chainId;     // The chain where the o-transaction is initiated
    bytes initiator;    // The contract address from which the o-transaction is initiated
    bytes from;         // The Omniverse account which signs the o-transaction
    uint8 op;           // The operation type
    bytes data;         // The operation data
    uint256 amount;     // The amount of token which is operated
    bytes signature;    // The signature of the above informations
}