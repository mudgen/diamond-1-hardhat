// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondMultiInit {    

    // This function is provided in the third parameter of the `diamondCut` function.
    // The `diamondCut` function executes this function to execute multiple initializer functions for a single upgrade.

    function multiInit(address[] calldata _addresses, bytes[] calldata _calldata) external {
        require(_addresses.length == _calldata.length, "Addresses and calldata length do not match.");
        for(uint i; i < _addresses.length; i++) {
            LibDiamond.initializeDiamondCut(_addresses[i], _calldata[i]);            
        }
    }
}
