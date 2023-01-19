// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice Omniverse transaction data structure
 * @member nonce: The number of the o-transactions. If the current nonce of an omniverse account is `k`, the valid nonce of this o-account in the next o-transaction is `k+1`. 
 * @member chainId: The chain where the o-transaction is initiated
 * @member initiateSC: The contract address from which the o-transaction is first initiated
 * @member from: The Omniverse account which signs the o-transaction
 * @member payload: The encoded bussiness logic data, which is maintained by the developer
 * @member signature: The signature of the above informations. 
 */
struct OmniverseTransactionData {
    uint128 nonce;
    uint32 chainId;
    bytes initiateSC;
    bytes from;
    bytes payload;
    bytes signature;
}