// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.16;
import {Modifiers} from "../../storage/LibAppStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CollectionMetaFacet is Modifiers {

    using Strings for uint256;

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
        uint256 imageNo = tokenId % 8;
        return
            string(abi.encodePacked(s._tokenURI, imageNo.toString(), '.png'));
    }
}