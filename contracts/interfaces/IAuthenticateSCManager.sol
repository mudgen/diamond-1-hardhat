// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAuthenticateSCManager {
    
    /// @notice used for register authenticated smart contract address
    /// @notice only the contract owner can call this method
    /// @param contractAddress        the to-authenticate smart contract address
    /// @param maxActiveNum           maximal number of NFT from the same contract address can be added into `_activeChildren`  
    /// 
    function register(address contractAddress, uint256 maxActiveNum) external;
    
    /// @notice    used for check if given contract address is authenticated to be directly added into `_activeChildren`
    /// @notice    when this contract address is not authenticated, the `maxActiveNum` returns 0
    /// @param     contractAddress        the to-authenticate smart contract address
    /// @return    authentic              check if the contract address has been registered
    /// @return    maxActiveNum           maximal number of NFT from the same contract address can be added into `_activeChildren`
    /// 
    function authenticated(address contractAddress) external view returns (bool authentic, uint256 maxActiveNum);

    /// @notice used for remove authenticated smart contract address
    /// @notice only the contract owner can call this method
    /// @param contractAddress        the de-authenticate smart contract address
    /// 
    function remove(address contractAddress) external;
}