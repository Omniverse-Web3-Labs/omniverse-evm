// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../OmniverseTransactionData.sol";

/**
 * @notice Interface of the ERC Omniverse-DLT
 */
interface IERCOmniverse {
    /**
     * @notice Emitted when a o-transaction which has nonce `nonce` and was signed by user `pk` is sent by calling {sendOmniverseTransaction}
     */
    event TransactionSent(bytes pk, uint256 nonce);

    /**
     * @notice Sends an omniverse transaction 
     * @dev 
     * Note: MUST implement the validation of the signature in `_data.signature`
     * Note: A map maintaining the omniverse accounts and their transaction nonces is RECOMMENDED 
     * Note: MUST implement the validation of the nonce in `_data.nonce` according to the current account nonce
     * Note: MUST implement the validation of the payload data
     * Note: This interface is just for sending of an omniverse transaction, and the execution MUST NOT be within this interface 
     * Note: The actual execution of an omniverse transaction is RECOMMENDED to be in another function and MAY be delayed for a time,
     * which is determined all by who publishes an O-DLT token
     * @param _data: the omniverse transaction data with type {OmniverseTransactionData}
     * See more information in the defination of {OmniverseTransactionData}
     *
     * Emit a {TransactionSent} event
     */
    function sendOmniverseTransaction(OmniverseTransactionData calldata _data) external;

    /**
     * @notice Get the number of omniverse transactions sent by user `_pk`, 
     * which is also the valid `nonce` of a new omniverse transactions of user `_pk` 
     * @param _pk: Omniverse account to be queried
     * @return The number of omniverse transactions sent by user `_pk`
     */
    function getTransactionCount(bytes memory _pk) external view returns (uint256);

    /**
     * @notice Get the transaction data `txData` and timestamp `timestamp` of the user `_use` at a specified nonce `_nonce`
     * @param _user Omniverse account to be queried
     * @param _nonce The nonce to be queried
     * @return Returns the transaction data `txData` and timestamp `timestamp` of the user `_use` at a specified nonce `_nonce`
     */
    function getTransactionData(bytes calldata _user, uint256 _nonce) external view returns (OmniverseTransactionData memory, uint256);

    /**
     * @notice Get the chain ID
     * @return Returns the chain ID
     */
    function getChainId() external view returns (uint32);
}