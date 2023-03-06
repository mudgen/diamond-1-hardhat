// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @notice The core struct of RMRK ownership.
 * @dev The `DirectOwner` struct is used to store information of the next immediate owner, be it the parent token or
 *  the externally owned account.
 * @dev If the token is owned by the externally owned account, the `tokenId` should equal `0`.
 * @param tokenId ID of the parent token
 * @param ownerAddress Address of the owner of the token. If the owner is another token, then the address should be
 *  the one of the parent token's collection smart contract. If the owner is externally owned account, the address
 *  should be the address of this account
 * @param isNft A boolean value signifying whether the token is owned by another token (`true`) or by an externally
 *  owned account (`false`)
 */
struct DirectOwner {
    uint256 tokenId;
    address ownerAddress;
    bool isNft;
}

/**
 * @notice The core child token struct, holding the information about the child tokens.
 * @return tokenId ID of the child token in the child token's collection smart contract
 * @return contractAddress Address of the child token's smart contract
 */
struct Child {
    uint256 tokenId;
    address contractAddress;
}
