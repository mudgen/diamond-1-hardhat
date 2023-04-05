// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Robin Bryce <robin@polysensus.com> (https://twitter.com/fupduk)
*
/******************************************************************************/

import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
import { IERC173 } from "./interfaces/IERC173.sol";
import { Proxy } from "./Proxy.sol";
import { LibTracker } from "./libraries/LibTracker.sol";

struct TrackerArgs {
    address diamondTarget;
    address owner;
}

/**
 * @dev this implementation is a simple proxy it is not, itself, a full diamond.
 * We just proxy the full IDiamondLoupe interface to the target diamond. Yes,
 * this doubles the indirection cost of every call. As the expected use of this
 * is ERC 4337 abstracted accounts, this overhead seems a fair trade.
 */
contract Tracker is Proxy, IDiamondLoupe, IERC165, IERC173 {

    constructor(TrackerArgs memory _args) payable {
        LibTracker.setContractOwner(_args.owner);
        LibTracker.setTarget(_args.diamondTarget);

        // Note: this implementation is NOT upgradable, see DiamondTracker for the full show.

        // So we do the ERC 165 configuration directly in the constructor
        // adding ERC165 data
        LibTracker.TrackerStorage storage s = LibTracker.trackerStorage();
        s.supportedInterfaces[type(IERC165).interfaceId] = true;
        // Notice: we don't implement the IDiamondCut interface, the tracked
        // diamond is probably not owned by the tracker.
        s.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        s.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    receive() external payable {}

    // ------------------------------------------
    // Proxy implementation
    // ------------------------------------------

    /// @notice get the implementation of msg.sig from the tracked diamond
    /// @ return facetAddress_ The facet address for msg.sig (from the target diamond)
    function _getImplementation() internal view virtual override returns (address implementation) {
        return _facetAddress(msg.sig);
    }
    /// @notice Gets the facet address that supports the given selector.
    function _facetAddress(bytes4 _functionSelector) internal view returns (address facetAddress_) {
        return IDiamondLoupe(LibTracker.getTarget()).facetAddress(_functionSelector);
    }

    // ------------------------------------------
    // This implements ERC-165.
    // ------------------------------------------

    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibTracker.TrackerStorage storage s = LibTracker.trackerStorage();
        return s.supportedInterfaces[_interfaceId];
    }

    // ------------------------------------------
    // ERC-173 implementation.
    // ------------------------------------------

    function transferOwnership(address _newOwner) external override {
        LibTracker.enforceIsContractOwner();
        LibTracker.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = LibTracker.contractOwner();
    }

    // ------------------------------------------
    // IDiamondLoupe implementation
    // ------------------------------------------
    /// @notice Gets all facets and their selectors.
    function facets() external override view returns (Facet[] memory facets_) {
        return IDiamondLoupe(LibTracker.getTarget()).facets();
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {
        return IDiamondLoupe(LibTracker.getTarget()).facetFunctionSelectors(_facet);
    }

    /// @notice Get all the facet addresses used by a diamond.
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        return IDiamondLoupe(LibTracker.getTarget()).facetAddresses();
    }

    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        return _facetAddress(_functionSelector);
    }
}
