// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.16;

/**
 * @title IRMRKCore
 * @author RMRK team
 * @notice Interface smart contract for RMRK core module.
 */
interface IRMRKCore {
    /**
     * @notice Used to retrieve the collection name.
     * @return string Name of the collection
     */
    function name() external view returns (string memory);

    /**
     * @notice Used to retrieve the collection symbol.
     * @return string Symbol of the collection
     */
    function symbol() external view returns (string memory);
}
