// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Robin Bryce <robin@polysensus.com> (https://twitter.com/fupduk)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

library LibTracker {
    bytes32 constant STORAGE_POSITION = keccak256("tracker.polysensus.storage");
    struct TrackerStorage {
        address trackedDiamond;
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

    function trackerStorage() internal pure returns (TrackerStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
