// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAppStorage, AppStorage} from "../storage/LibAppStorage.sol";

contract MintAndBurnFacetInit {

    /**
     * init setup for royalty info facet
     */
    function init(uint256 maxSupply, uint256 pricePerMint) public {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._maxSupply = maxSupply;
        s._pricePerMint = pricePerMint;
    }
}