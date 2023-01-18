// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Omniverse transaction data structure
 * @Member nonce: The serial number of an o-transactions sent from an Omniverse Account. If the current nonce of an o-account is k, the valid nonce in the next o-transaction is k+1. 
 * @Member chainId: The chain where the o-transaction is initiated
 * @Member initiateSC: The contract address from which the o-transaction is first initiated
 * @Member from: The Omniverse account which signs the o-transaction
 * @Member payload: The encoded bussiness logic data, which is maintained by the developer
 * @Member signature: The signature of the above informations. 
 */
struct OmniverseTransactionData {
    uint128 nonce;
    uint32 chainId;
    bytes initiateSC;
    bytes from;
    bytes payload;
    bytes signature;
}