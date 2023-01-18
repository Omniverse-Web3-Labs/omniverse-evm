// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERCOmniverse.sol";

/**
 * @notice Interface of the omniverse fungible token, which inherits {IERCOmniverse}
 */
interface IERCOmniverseFungible is IERCOmniverse {
    /**
     * @notice Get the omniverse balance of a user `_pk`
     * @param _pk Omniverse account to be queried
     * @return Returns the omniverse balance of a user `_pk`
     */
    function omniverseBalanceOf(bytes calldata _pk) external view returns (uint256);
}