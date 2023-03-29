// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.16;

import { LibAppStorage, AppStorage } from "../../storage/LibAppStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibQuery {

    using Strings for uint256;

    /**
     * @notice Used to retrieve the metadata URI of a token.
     * @param tokenId ID of the token to retrieve the metadata URI for
     * @return Metadata URI of the specified token
     */
    function tokenURI(
        uint256 tokenId
    ) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return
            string(abi.encodePacked(s._tokenURI, tokenId.toString()));
    }
}