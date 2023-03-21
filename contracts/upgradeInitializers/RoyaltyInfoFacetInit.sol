// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAppStorage, AppStorage} from "../storage/LibAppStorage.sol";

contract RoyaltyInfoFacetInit {

    /**
     * init setup for royalty info facet
     */
    function init(address royaltyRecipient, uint256 royaltyPercentage) public {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._royaltyRecipient = royaltyRecipient;
        s._royaltyPercentageBps = royaltyPercentage;
    }
}