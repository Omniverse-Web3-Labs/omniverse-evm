// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERCOmniverse.sol";

/**
 * @notice Interface of the omniverse non fungible token, which inherits {IERCOmniverse}
 */
interface IERCOmniverseNonFungible is IERCOmniverse {
    /**
     * @notice Get the number of tokens in account `_pk`
     * @param _pk Omniverse account to be queried
     * @return Returns the number of tokens in account `_pk`
     */
    function omniverseBalanceOf(bytes calldata _pk) external view returns (uint256);

    /**
     * @notice Get the owner of a token `tokenId`
     * @param _tokenId Omniverse token id to be queried
     * @return Returns the owner of a token `tokenId`
     */
    function omniverseOwnerOf(uint256 _tokenId) external view returns (bytes memory);
}