// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.16;

import { LibAppStorage, AppStorage } from "../../storage/LibAppStorage.sol";
import { IAuthenticateSCManager } from "../../interfaces/IAuthenticateSCManager.sol";
import "../../interfaces/IRMRKNestable.sol";
import "../../shared/RMRKErrors.sol";

library LibNestable {
     /**
     * @notice Used to notify listeners that the token is being transferred.
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param from Address of the previous immediate owner, which is a smart contract if the token was nested.
     * @param to Address of the new immediate owner, which is a smart contract if the token is being nested.
     * @param fromTokenId ID of the previous parent token. If the token was not nested before, the value should be `0`
     * @param toTokenId ID of the new parent token. If the token is not being nested, the value should be `0`
     * @param tokenId ID of the token being transferred
     */
    event NestTransfer(address indexed from, address indexed to, uint256 fromTokenId, uint256 toTokenId, uint256 indexed tokenId);

    /**
     * @notice Used to notify listeners that a new token has been added to a given token's pending children array.
     * @dev Emitted when a child NFT is added to a token's pending array.
     * @param tokenId ID of the token that received a new pending child token
     * @param childAddress Address of the proposed child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     * @param childIndex Index of the proposed child token in the parent token's pending children array
     */
    event ChildProposed(uint256 indexed tokenId, uint256 childIndex, address indexed childAddress, uint256 indexed childId);

    /**
     * @notice Used to notify listeners that a new child token was accepted by the parent token.
     * @dev Emitted when a parent token accepts a token from its pending array, migrating it to the active array.
     * @param tokenId ID of the token that accepted a new child token
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     * @param childIndex Index of the newly accepted child token in the parent token's active children array
     */
    event ChildAccepted(uint256 indexed tokenId, uint256 childIndex, address indexed childAddress, uint256 indexed childId);

    /**
     * @notice Used to notify listeners that all pending child tokens of a given token have been rejected.
     * @dev Emitted when a token removes all a child tokens from its pending array.
     * @param tokenId ID of the token that rejected all of the pending children
     */
    event AllChildrenRejected(uint256 indexed tokenId);

    /**
     * @notice Used to notify listeners a child token has been transferred from parent token.
     * @dev Emitted when a token transfers a child from itself, transferring ownership to the root owner.
     * @param tokenId ID of the token that transferred a child token
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     * @param childIndex Index of a child in the array from which it is being transferred
     * @param fromPending A boolean value signifying whether the token was in the pending child tokens array (`true`) or
     *  in the active child tokens array (`false`)
     */
    event ChildTransferred(uint256 indexed tokenId, uint256 childIndex, address indexed childAddress, uint256 indexed childId, bool fromPending);

    /**
     * @notice Used to enforce that the given token has been minted.
     * @dev Reverts if the `tokenId` has not been minted yet.
     * @dev The validation checks whether the owner of a given token is a `0x0` address and considers it not minted if
     *  it is. This means that both tokens that haven't been minted yet as well as the ones that have already been
     *  burned will cause the transaction to be reverted.
     * @param tokenId ID of the token to check
     */
    function _requireMinted(uint256 tokenId) internal view  {
        require(_exists(tokenId), "invalid token id!");
    }

    /**
     * @notice Used to check whether the given token exists.
     * @dev Tokens start existing when they are minted (`_mint`) and stop existing when they are burned (`_burn`).
     * @param tokenId ID of the token being checked
     * @return bool The boolean value signifying whether the token exists
     */
    function _exists(uint256 tokenId) internal view  returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.owner[tokenId] != address(0);
    }

    /**
     * @notice used to check if current child NFT address is authenticated and maximal active children number for this NFT
     * @param   childNFTAddress     child nft origin smart contract address
     * @return  bool                true: the child NFT smart contract is authenticated
     * @return  uint256             maximal active children number for this child NFT
     */
    function _authenticated(address childNFTAddress) internal view returns (bool, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address scManagerAddress = s._authenticateSCManager;

        bool authentic;
        uint256 maxActiveNum;
        (authentic, maxActiveNum) = IAuthenticateSCManager(scManagerAddress).authenticated(childNFTAddress);

        return (authentic, maxActiveNum);
    }

    /**
     * @notice used to append child NFT to main NFT
     * @param   childNFTAddress     child NFT original smart contract address
     * @param   parentId            id of the main NFT
     * @param   childId             id of the child id in its original smart contract
     */
    function appendChild(address childNFTAddress, uint256 parentId, uint256 childId) internal {        
        (bool authentic, uint256 maxActiveNum) = _authenticated(childNFTAddress);
        Child memory child = Child({contractAddress: childNFTAddress, tokenId: childId});

        // check if current child NFT address is authenticated
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (authentic && s._activeChildrenAddressCount[parentId][childNFTAddress] < maxActiveNum) {
            addToActiveChildren(child, parentId);
        } else {
            addToPendingChildren(child, parentId);
        }
    }

    /**
     * @notice Used to retrieve the pending child tokens of a given parent token.
     * @dev Returns array of pending Child structs existing for given parent.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the pending child tokens
     * @return struct[] An array of Child structs containing the parent token's pending child tokens
     */
    function pendingChildrenOf(uint256 parentId) internal view  returns (Child[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Child[] memory pendingChildren = s._pendingChildren[parentId];
        return pendingChildren;
    }

    /**
     * @notice  Used to add pending children
     * @dev     check if maximal number of pending children is reach
     * @param   child       the to-pending child instance
     * @param   parentId    the parent id in current contract
     */
    function addToPendingChildren(Child memory child, uint256 parentId) internal {
        uint256 length = pendingChildrenOf(parentId).length;

        if (length < 128) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            s._pendingChildren[parentId].push(child);
        } else {
            revert RMRKMaxPendingChildrenReached();
        }
        // Previous length matches the index for the new child
        emit ChildProposed(parentId, length, child.contractAddress, child.tokenId);
    }

    /**
     * @notice  Used to add active children
     * @dev     check if maximal number of active children from this contract has reach
     * @param   child       the to-appending child instance
     * @param   parentId    the parent id in current contract
     */
    function addToActiveChildren(Child memory child, uint256 parentId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address childAddress = child.contractAddress;
        uint256 childId = child.tokenId;

        require(s._childIsInActive[childAddress][childId] == 0, "child already exists");
        
        uint256 childIndex = s._activeChildren[parentId].length;
        
        s._activeChildren[parentId].push(child);
        s._childIsInActive[childAddress][childId] = 1; // We use 1 as true
        s._activeChildrenAddressCount[parentId][childAddress]++;

        emit ChildAccepted(parentId, childIndex, childAddress, childId);
    }
}