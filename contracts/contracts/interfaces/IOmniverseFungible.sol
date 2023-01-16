// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../OmniverseTransactionData.sol";

interface IOmniverseFungible {
    /**
     * @dev Send an omniverse transaction
     */
    function sendOmniverseTransaction(OmniverseTransactionData calldata _data) external;

    /**
     * @dev Returns the count of transactions
     */
    function getTransactionCount(bytes memory _pk) external view returns (uint256);

    /**
     * @dev Returns the transaction data of the user with a specified nonce
     */
    function getTransactionData(bytes calldata _user, uint256 _nonce) external view returns (OmniverseTransactionData memory txData, uint256 timestamp);

    /**
     * @dev Returns the chain ID
     */
    function getChainId() external view returns (uint32);

    /**
     * @dev Returns the omniverse balance of a user
     */
    function omniverseBalanceOf(bytes calldata _pk) external view returns (uint256);
}