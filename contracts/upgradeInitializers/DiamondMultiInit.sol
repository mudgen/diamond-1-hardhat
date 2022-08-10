// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

// This function provides a way to call multiple initialization functions from multiple
// addresses for a single upgrade.

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondMultiInit {    

    function multiInit(address[] calldata _addresses, bytes[] calldata _calldata) external {
        require(_addresses.length == _calldata.length, "Addresses and calldata length do not match.");
        for(uint i; i < _addresses.length; i++) {
            LibDiamond.initializeDiamondCut(_addresses[i], _calldata[i]);            
        }
    }
}
