// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.16;

import { Modifiers } from "../../storage/LibAppStorage.sol";
import { LibMint } from "../libs/LibMint.sol";
import { LibMeta } from "../../shared/LibMeta.sol";
import { LibBurn } from "../libs/LibBurn.sol";

contract RMRKMintAndBurnFacet is Modifiers {

    
    ////////////////////////////////////////
    //              MINTING
    ////////////////////////////////////////
    /**
     * @notice Used for minting a new NFT
     * 
     * @param to    the target owner for newly minted NFT
     */
    function mint(address to) public payable {

        // before minting: requirements:
        // - cannot transcend `_maxSupply`
        // - payment value is greater than the preset `_pricePerMint`
        uint256 nextToken = LibMint.beforeMint(to);
        LibMint.safeMint(to, nextToken, "");
    }

    ////////////////////////////////////////
    //              BURNING
    ////////////////////////////////////////

    /**
     * @notice Used for burning a new NFT
     * @dev requirements:
     *
     * - should be the owner of approved role of this NFT
     *
     * @param tokenId ID of the token to burn
     */
    function burn(uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
        LibBurn._burn(tokenId);
    }
}