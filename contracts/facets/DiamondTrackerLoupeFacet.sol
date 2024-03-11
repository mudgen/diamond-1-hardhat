// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Robin Bryce <robin@polysensus.com> (https://twitter.com/fupduk)
* Diamond Tracker aware Louper implementation
/******************************************************************************/

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";

// note: there is no special reason to have the IERC165 implementation on the
// Loupe facet. To remain consistent with the orignal reference diamond
// implementation, the DiamondTrackerLoupe retains this.
import { IERC165 } from "../interfaces/IERC165.sol";
import { LibDiamond } from  "../libraries/LibDiamond.sol";
import { LibDiamondLouper } from  "../libraries/LibDiamondLouper.sol";
import { LibTracker } from  "../libraries/LibTracker.sol";

contract DiamondTrackerLoupeFacet is IDiamondLoupe, IERC165 {

    /// @dev MUST aggregate local and target diamond facets
    function facets() external override view returns (Facet[] memory facets_) {

        // XXX: TODO: work a bit harder to avoid redundant allocation and copying
        Facet[]memory localFacets = LibDiamondLouper.facets();
        Facet[]memory targetFacets = IDiamondLoupe(LibTracker.getTarget()).facets();
        facets_ = new Facet[](localFacets.length + targetFacets.length);

        uint256 facetCount = localFacets.length;
        for (uint256 facetIndex; facetIndex < facetCount; facetIndex++) {
            facets_[facetIndex].facetAddress = localFacets[facetIndex].facetAddress;
            facets_[facetIndex].functionSelectors = localFacets[facetIndex].functionSelectors;
        }

        uint256 targetFacetIndex;
        facetCount = localFacets.length + targetFacets.length;
        for (uint256 facetIndex = localFacets.length; facetIndex < facetCount; facetIndex++) {
            facets_[facetIndex].facetAddress = targetFacets[targetFacetIndex].facetAddress;
            facets_[facetIndex].functionSelectors = targetFacets[targetFacetIndex].functionSelectors;
            targetFacetIndex ++;
        }
    }

    /// @dev IDiamondLoupe.facetFunctionSelectors MUST support local facets and proxied - if the facet isn't local, proxy the call.
    function facetFunctionSelectors(
        address _facet
        ) external override view returns (bytes4[] memory _facetFunctionSelectors) {

        // First check for the facet locally, if it is present ALL of its
        // selectors take precedence. And it doesn't matter if the same facet is
        // also cut into the target diamond - its the same address, and hence same code.

        _facetFunctionSelectors = LibDiamondLouper.facetFunctionSelectors(_facet);
        if (_facetFunctionSelectors.length > 0) return _facetFunctionSelectors;

        // Ok, we have zero selectors for this facet locally, try the diamond target.

        return IDiamondLoupe(LibTracker.getTarget()).facetFunctionSelectors(_facet);
    }

    /// @dev IDiamondLoupe.facetAddresses MUST aggregate the addresses from the tracked and the remote
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        // XXX: TODO make this more allocation and op count friendly
        address[] memory localAddresses = LibDiamondLouper.facetAddresses();
        address[] memory targetAddresses = IDiamondLoupe(LibTracker.getTarget()).facetAddresses();
        facetAddresses_ = new address[](localAddresses.length + targetAddresses.length);

        uint256 facetCount = localAddresses.length;
        for (uint256 facetIndex; facetIndex < facetCount; facetIndex++) {
            facetAddresses_[facetIndex] = localAddresses[facetIndex];
        }

        uint256 targetFacetIndex;
        facetCount = localAddresses.length + targetAddresses.length;
        for (uint256 facetIndex = localAddresses.length; facetIndex < facetCount; facetIndex++) {
            facetAddresses_[facetIndex] = targetAddresses[targetFacetIndex];
            targetFacetIndex ++;
        }
    }

    /// @dev IDiamondLoupe.facetAddress MUST support local and proxied function selectors
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.facetAddressAndSelectorPosition[_functionSelector].facetAddress;
        if (facetAddress_ != address(0)) return facetAddress_;
        return IDiamondLoupe(LibTracker.getTarget()).facetAddress(_functionSelector);
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}