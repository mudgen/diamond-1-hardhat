// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Robin Bryce <robin@polysensus.com> (https://twitter.com/fupduk)
*
/******************************************************************************/

import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { Proxy } from "./Proxy.sol";

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { LibTracker } from "./libraries/LibTracker.sol";

struct DiamondTrackerArgs {
    address diamondTarget;
    address owner;
    address init;
    bytes initCalldata;
}

contract DiamondTracker is Proxy {

    constructor(IDiamondCut.FacetCut[] memory _diamondCut, DiamondTrackerArgs memory _args) payable {
        LibDiamond.setContractOwner(_args.owner);
        LibTracker.setTarget(_args.diamondTarget);
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);

        // Code can be added here to perform actions and set state variables.
    }

    receive() external payable {}

    /// @notice Gets the facet address that supports the given selector.
    function _facetAddress(bytes4 _functionSelector) internal view returns (address facetAddress_) {
        return IDiamondLoupe(LibTracker.getTarget()).facetAddress(_functionSelector);
    }

    function _getLocalImplementation() internal view returns (address implementation) {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        return ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
    }

    function _getImplementation() internal view virtual override returns (address imp) {
        // Is the implementation found on the local diamond. Note this means all
        // diamond facets that are cut into the tracker have special considerations:
        // a.) IDiamondCut MUST NOT proxy (the owner would be wrong anyway)
        // b.) IDiamondLoupe.facets MUST aggregate the facets from the tracked target with the local selectors.
        // c.) IDiamondLoupe.facetFunctionSelectors MUST support local facets and proxied - if the facet isn't local, proxy the call.
        // d.) IDiamondLoupe.facetAddresses MUST aggregate the addresses from the tracked and the remove
        // e.) IDiamondLoupe.facetAddress MUST support local and proxied function selectors

        // z.) For conveneince, when returning aggregate results the tracker MUST list the local results before the results from the proxy.

        imp = _getLocalImplementation();
        if (imp != address(0)) return imp;
        imp = _facetAddress(msg.sig);
    }
}