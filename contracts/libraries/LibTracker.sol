// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Robin Bryce <robin@polysensus.com> (https://twitter.com/fupduk)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

error NotContractOwner(address _user, address _contractOwner);

library LibTracker {
    bytes32 constant STORAGE_POSITION = keccak256("tracker.polysensus.storage");
    struct TrackerStorage {
        mapping(bytes4 => bool) supportedInterfaces;
        address trackedDiamond;
        address contractOwner;
    }

    event TargetChanged(address indexed previousTarget, address indexed newTarget);

    function setTarget(address _diamond) internal {
        TrackerStorage storage s = trackerStorage();
        address previous = s.trackedDiamond;
        s.trackedDiamond = _diamond;
        emit TargetChanged(previous, _diamond);
    }
    function getTarget() internal view returns (address diamond) {
        diamond = trackerStorage().trackedDiamond;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        TrackerStorage storage s = trackerStorage();
        address previousOwner = s.contractOwner;
        s.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = trackerStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if(msg.sender != trackerStorage().contractOwner) {
            revert NotContractOwner(msg.sender, trackerStorage().contractOwner);
        }        
    }

    function trackerStorage() internal pure returns (TrackerStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
