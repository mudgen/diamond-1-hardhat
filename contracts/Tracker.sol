// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Robin Bryce <robin@polysensus.com> (https://twitter.com/fupduk)
*
/******************************************************************************/

import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
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
contract Tracker is Proxy, IDiamondLoupe {

    constructor(TrackerArgs memory _args) payable {
        LibTracker.setTarget(_args.diamondTarget);

        // Note: this implementation is NOT upgradable, see DiamondTracker for the full show.

        // Note: ERC 165 & ERC 173 support are illustrated in DiamondTracker
        // (which is the variant that supports user customization and opt outs)
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
