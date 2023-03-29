// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.16;

import { LibAppStorage, AppStorage } from "../../storage/LibAppStorage.sol";
import { LibMeta } from "../../shared/LibMeta.sol";
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
    function ownerOf(uint256 tokenId) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // change: the Nain NFT should only implement `ownerOf` method, since there will be no parent NFT above it
        return s.owner[tokenId];
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

    function approve(address to, uint256 tokenId) internal  {
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

    function isApprovedForAll(address owner, address operator) internal view  returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._operatorApprovals[owner][operator];
    }

    function getApproved(uint256 tokenId) internal view  returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        LibNestable._requireMinted(tokenId);

        return s._tokenApprovals[tokenId][ownerOf(tokenId)];
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

    /**
     * @notice Used to update the owner of the token and clear the approvals associated with the previous owner.
     * @dev The `destinationId` should equal `0` if the new owner is an externally owned account.
     * @param tokenId ID of the token being updated
     * @param to Address of account to receive the token
     */
    function _updateOwnerAndClearApprovals(uint256 tokenId, address to) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address owner = s.owner[tokenId];

        s.owner[tokenId] = to;

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        delete s._tokenApprovals[tokenId][owner];    
    }

    
    function confirmOwnership(address _owner, uint256 _tokenId) internal {
        require(_owner != address(0x0), "Owner must be valid");
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._ownersToTokenIds[_owner].push(_tokenId);
        uint256 newTokenIndex = uint256(s._ownersToTokenIds[_owner].length - 1);
        s._tokenIdToOwnerIndex[_tokenId] = newTokenIndex;
    }

    function removeOwnership(address _owner, uint256 _tokenId) internal {
        require(_owner != address(0x0), "Owner must be valid");
        require(ownerOf(_tokenId) == _owner, "not the real owner");
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 tokenIndex = s._tokenIdToOwnerIndex[_tokenId];
        if (tokenIndex != s._ownersToTokenIds[_owner].length - 1) {
            uint256 lastTokenId = s._ownersToTokenIds[_owner][s._ownersToTokenIds[_owner].length - 1];
            s._ownersToTokenIds[_owner][tokenIndex] = lastTokenId;
            s._tokenIdToOwnerIndex[lastTokenId] = tokenIndex;
            s._ownersToTokenIds[_owner].pop();
        }
    }
}