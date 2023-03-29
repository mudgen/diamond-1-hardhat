// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.16;
import {Modifiers} from "../../storage/LibAppStorage.sol";
import {LibQuery} from "../libs/LibQuery.sol";

contract CollectionMetaFacet is Modifiers {

    /**
     * @notice Used to retrieve the metadata of the collection.
     * @return string The metadata URI of the collection
     */
    function collectionMetadata() public view returns (string memory) {
        return s._collectionMeta;
    }

    /**
     * @notice Used to retrieve the metadata URI of a token.
     * @param tokenId ID of the token to retrieve the metadata URI for
     * @return Metadata URI of the specified token
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        return LibQuery.tokenURI(tokenId);
    }
}