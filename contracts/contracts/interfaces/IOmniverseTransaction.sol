// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../OmniverseTransactionData.sol";

/**
 * @dev Interface of the omniverse DLT
 */
interface IERCOmniverse {
    /**
     * @dev Emitted when a transaction which has nonce `nonce` and was signed by user `pk` is executed
     */
    event TransactionSent(bytes pk, uint256 nonce);

    /**
     * @dev Sends an omniverse transaction with omniverse transaction data `_data`
     * NOTE The transaction MUST be deferred executed, and the developer should implement a trigger mechanism
     * @param _data Omniverse transaction data
     * See more information in OmniverseTransactionData.sol
     *
     * Emit a {TransactionSent} event
     */
    function sendOmniverseTransaction(OmniverseTransactionData calldata _data) external;

    /**
     * @dev Returns the count of transactions sent by user `_pk`
     * @param _pk Omniverse account to be queried
     */
    function getTransactionCount(bytes memory _pk) external view returns (uint256);

    /**
     * @dev Returns the transaction data `txData` and timestamp `timestamp` of the user `_use` at a specified nonce `_nonce`
     * @param _user Omniverse account to be queried
     * @param _nonce The nonce to be queried
     */
    function getTransactionData(bytes calldata _user, uint256 _nonce) external view returns (OmniverseTransactionData memory, uint256);

    /**
     * @dev Returns the chain ID
     */
    function getChainId() external view returns (uint32);
}