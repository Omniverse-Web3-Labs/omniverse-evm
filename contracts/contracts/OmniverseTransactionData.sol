// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Omniverse transaction data structure, different `op` indicates different type of omniverse transaction
 * nonce: The number of o-transactions sent from a user
 * chainId: The chain where the o-transaction is initiated
 * initiator: The contract address from which the o-transaction is initiated
 * from: The Omniverse account which signs the o-transaction
 * data: The encoded bussiness logic data, which is maintained by the developer.
 * NOTE Take {SkywalkerFungible.sol - Fungible} for example
 * signature: The signature of the above informations
 */
struct OmniverseTransactionData {
    uint128 nonce;
    uint32 chainId;
    bytes initiator;
    bytes from;
    bytes data;
    bytes signature;
}