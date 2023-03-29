// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.16;
import { LibAppStorage, AppStorage } from "../../storage/LibAppStorage.sol";
import { LibOwnership } from "../libs/LibOwnership.sol";
import { LibERC721 } from "../../libraries/LibERC721.sol";

library LibBurn {

    /**
     * @notice Used to burn a token.
     * @dev For this implementation, the burnt token's children will NOT be burnt, for a burning method including burning its child, please upgrade the `MintAndBurnFacet`
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param tokenId ID of the token to burn
     */
    function _burn(uint256 tokenId) internal {
        address owner = LibOwnership.ownerOf(tokenId);
        AppStorage storage s = LibAppStorage.diamondStorage();

        s._balances[owner] -= 1;
        LibOwnership._approve(address(0), tokenId);
        
        delete s._activeChildren[tokenId];
        delete s._pendingChildren[tokenId];
        delete s._tokenApprovals[tokenId][owner];

        delete s.owner[tokenId];

        LibOwnership.removeOwnership(owner, tokenId);

        emit LibERC721.Transfer(owner, address(0), tokenId);
    }
}