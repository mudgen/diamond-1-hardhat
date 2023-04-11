// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.16;
import {Modifiers} from "../../storage/LibAppStorage.sol";

contract BaseInfoFacet is Modifiers {

    /**
     * @notice Used to retrieve the collection name.
     * @return string Name of the collection
     */
    function name() public view returns (string memory) {
        return s._name;
    }

    /**
     * @notice Used to retrieve the collection symbol.
     * @return string Symbol of the collection
     */
    function symbol() public view returns (string memory) {
        return s._symbol;
    }

    /**
     * @notice Used to retrieve the maximum supply of the collection.
     * @return The maximum supply of tokens in the collection
     */
    function maxSupply() public view returns (uint256) {
        return s._maxSupply;
    }

    /**
     * @notice Used to get authenticate smart contract manager address
     * @return The authenticate smart contract manager address
     */
    function authenticateSCManagerAddress() public view returns (address) {
        return s._authenticateSCManager;
    }
}