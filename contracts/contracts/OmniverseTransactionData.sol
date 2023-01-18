// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Omniverse transaction data structure
 * @Member nonce: The serial number of an o-transactions sent from an Omniverse Account. If the current nonce of an o-account is k, the valid nonce in the next o-transaction is k+1. 
 * @Member chainId: The chain where the o-transaction is initiated
 * @Member initiateSC: The contract address from which the o-transaction is first initiated
 * @Member from: The Omniverse account which signs the o-transaction
 * @Member payload: The encoded bussiness logic data, which is maintained by the developer
 * NOTE Take {./libraries/SkywalkerFungibleHelper.sol - Fungible} for example
 * @Member signature: The signature of the above informations. 
 * NOTE Firstly, the above sectors are combined as:
 * `bytes memory rawData = abi.encodePacked(o.nonce, o.chainId, o.initiator, o.from, rawPayload);`,
 * where the `o` is an instance of the struct, and the `rawPayload` which is used to compute the `rawData`
 * is derived from `payload`. The `rawPayload` may be the same as `payload`, it depends on the system design scheme.
 * Take {./libraries/SkywalkerFungibleHelper.sol - SkywalkerFungibleHelper - getTransactionHash} for example
 * Secondly, the raw data is hashed by `bytes32 hash = keccak256(rawData)`
 * Thirdly, sign the hash and set the signature to the field `signature`.
 */
struct OmniverseTransactionData {
    uint128 nonce;
    uint32 chainId;
    bytes initiateSC;
    bytes from;
    bytes payload;
    bytes signature;
}