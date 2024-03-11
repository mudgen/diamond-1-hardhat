// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Robin Bryce <robin@polysensus.com> (https://twitter.com/fupduk)
*
* Proxy abstract defining a diamond compatible fallback and requiring the
* implementation of _getImplementation in deriving contracts.
* Note: The _getImplementation approach is due to solidstate
*       See https://github.com/solidstate-network/solidstate-solidity.git (MIT)
/******************************************************************************/

// When no function exists for function called
error FunctionNotFound(bytes4 _functionSelector);

abstract contract Proxy {

    // Find implementation for the missing msg.sig. Delegate execution to that
    // address for msg.sig and return any value.
    // If no implementation is found, revert
    fallback() external payable {
        address imp = _getImplementation();
        if(imp == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
             // execute function call using the facet
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
     * @notice returns an address which implements msg.sig
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}