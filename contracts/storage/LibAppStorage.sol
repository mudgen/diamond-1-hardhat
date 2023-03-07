// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../libraries/LibRMRKNestable.sol";

/*
 * Storage Slot Defination In a Human Readable Format
 * For an upgradable smart contract,
 *  it is never TOO cautious on the storage slot distribution
 * This implementation follows the 'AppStorage Pattern' to come up with a more humanreadable storage allocation
 * For detailed information, please refer to
 * https://eip2535diamonds.substack.com/p/appstorage-pattern-for-state-variables?s=w
 *
 * For every NEWLY introduced storage, developers should design the storage pattern in AppStorage to have a better accessing performance.
 */

/**
 * Common storage for diamond project
 */
struct AppStorage {

    // base info
    /// Token name
    string _name;

    /// Token symbol
    string _symbol;

    // Mapping owner address to token count
    mapping(address => uint256) _balances;
    // Mapping from token ID to approver address to approved address
    // The approver is necessary so approvals are invalidated for nested children on transfer
    // WARNING: If a child NFT returns to a previous root owner, old permissions would be active again
    mapping(uint256 => mapping(address => address)) _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
    // ------------------- NESTABLE --------------

    // Mapping from token ID to DirectOwner struct
    mapping(uint256 => DirectOwner) _RMRKOwners;
    // Mapping of tokenId to array of active children structs
    mapping(uint256 => Child[]) _activeChildren;
    // Mapping of tokenId to array of pending children structs
    mapping(uint256 => Child[]) _pendingChildren;
    // Mapping of child token address to child token ID to whether they are pending or active on any token
    // We might have a first extra mapping from token ID, but since the same child cannot be nested into multiple tokens
    //  we can strip it for size/gas savings.
    mapping(address => mapping(uint256 => uint256)) _childIsInActive;
    // Mapping of owner address to all tokenIDs
    mapping(address => uint256[]) _ownersToTokenIds;
}

/**
 * AppStorage pattern library, this will ensure every facet will interact with the RIGHT storage address inside the diamond contract
 * For detailed information, please refer to: https://eip2535diamonds.substack.com/p/appstorage-pattern-for-state-variables?s=w
 */
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

/**
 * A base contract with common AppStorage defined that can prevent storage collisions,
 * with some decoration common usage defined
 */
contract Modifiers {
    AppStorage internal s;

    /**
     * Decoration: should check if the msg.sender is the contract owner
     */
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
