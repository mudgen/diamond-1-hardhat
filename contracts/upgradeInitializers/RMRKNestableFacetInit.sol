// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAppStorage, AppStorage} from "../storage/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IRMRKNestable} from "../interfaces/IRMRKNestable.sol";

contract RMRKNestableFacetInit {
    /**
     * init setup for RMRKNestable Facet plugin
     */
    function init(string memory name, string memory symbol, address authenticateSCAddress) public {
        AppStorage storage s = LibAppStorage.diamondStorage();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        s._name = name;
        s._symbol = symbol;
        s._authenticateSCManager = authenticateSCAddress;

        // support RMRKNestable interface
        ds.supportedInterfaces[type(IRMRKNestable).interfaceId] = true;

    }
}
