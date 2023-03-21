// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAppStorage, AppStorage} from "../storage/LibAppStorage.sol";

contract CollectionMetaFacetInit {

    /**
     * init setup for royalty info facet
     */
    function init(
                string memory collectionMeta, 
                string memory tokenURI
                ) public {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._collectionMeta = collectionMeta;
        s._tokenURI = tokenURI;
    }
}