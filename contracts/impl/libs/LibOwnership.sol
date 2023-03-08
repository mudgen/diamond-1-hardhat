// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.16;

import { LibAppStorage, AppStorage } from "../../storage/LibAppStorage.sol";
import { LibMeta } from "./LibMeta.sol"; 
import {LibERC721} from "../../libraries/LibERC721.sol";
import {LibNestable} from "./LibNestable.sol";

library LibOwnership {

    ////////////////////////////////////////
    //              Ownership
    ////////////////////////////////////////

    /**
     * query the owner of `tokenId`
     * @param tokenId:  token id in query
     * @return          owner address of this token
     */ 
    function ownerOf(uint256 tokenId) public view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // change: the Nain NFT should only implement `ownerOf` method, since there will be no parent NFT above it
        return s._RMRKOwners[tokenId].ownerAddress;
    }

    // No `directOwnerOf` method ANY MORE

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @dev If the caller is not the owner of the token or approved to manage it by its owner, the execution will be
     *  reverted.
     * @param tokenId ID of the token to check
     */
    function _onlyApprovedOrOwner(uint256 tokenId) private view {
        require(_isApprovedOrOwner(LibMeta._msgSender(), tokenId), "Not approved or owner");
    }

    ////////////////////////////////////////
    //              APPROVALS
    ////////////////////////////////////////

    function approve(address to, uint256 tokenId) public  {
        address owner = ownerOf(tokenId);
        require(to != owner, "Cannot approve to current owner!");
        require(LibMeta._msgSender() == owner || isApprovedForAll(owner, LibMeta._msgSender()), "approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    /*
     * @notice Used to grant an approval to manage a given token.
     * @dev Emits an {Approval} event.
     * @param to Address to which the approval is being granted
     * @param tokenId ID of the token for which the approval is being granted
     */
    function _approve(address to, uint256 tokenId) internal  {
        address owner = ownerOf(tokenId);

        AppStorage storage s = LibAppStorage.diamondStorage();
        s._tokenApprovals[tokenId][owner] = to;

        emit LibERC721.Approval(owner, to, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view  returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._operatorApprovals[owner][operator];
    }

    function getApproved(uint256 tokenId) public view  returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        LibNestable._requireMinted(tokenId);

        return s._tokenApprovals[tokenId][ownerOf(tokenId)];
    }

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _onlyApprovedOrOwner(tokenId);
        _;
    }

    /**
     * @notice Used to check whether the given account is allowed to manage the given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param spender Address that is being checked for approval
     * @param tokenId ID of the token being checked
     * @return bool The boolean value indicating whether the `spender` is approved to manage the given token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view  returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
}