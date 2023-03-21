// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.16;
import {Modifiers} from "../../storage/LibAppStorage.sol";
import "../../shared/RMRKErrors.sol";
import { LibOwnership } from "../libs/LibOwnership.sol";
import { LibTransfer } from "../libs/LibTransfer.sol";

/**
 * Transfer functionality for RMRK NFTs
 */
contract RMRKTransferFacet is Modifiers {

    /**
     * @notice Used to tranfer the token from `from` to `to`
     * @dev this `transfer` method will NOT check if the 「contract」 recipients are aware of ERC721 protocol
     *      the transfered token maybe permanently locked
     * @dev Requirements: 
     *
     *      - the `from` address should either be the owner of the `tokenId` or have operator role for the owner's collection or the given `tokenId`
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
        LibTransfer._transfer(from, to, tokenId, "");
    }

    /**
     * @notice Used to 「safely」 tranfer the token from `from` to `to`
     * @dev this `transfer` method will check if the 「contract」 recipients are aware of ERC721 protocol
     *      the transfered token maybe permanently locked
     * @dev Requirements: 
     *
     *      - the `from` address should either be the owner of the `tokenId` or have operator role for the owner's collection or the given `tokenId`
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
        LibTransfer._safeTransfer(from, to, tokenId, "");
    }

}