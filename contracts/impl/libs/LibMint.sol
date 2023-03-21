// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.16;
import { LibAppStorage, AppStorage } from "../../storage/LibAppStorage.sol";
import { RMRKMintOverMax, RMRKMintUnderpriced, ERC721TransferToNonReceiverImplementer, ERC721MintToTheZeroAddress, ERC721TokenAlreadyMinted, RMRKIdZeroForbidden } from "../../shared/RMRKErrors.sol";
import { LibMeta } from "../../shared/LibMeta.sol";
import { LibERC721 } from "../../libraries/LibERC721.sol";
import { LibNestable } from "./LibNestable.sol";

library LibMint {

    /**
     * @notice Used for checking if current minting process can continue
     * @dev requirements:
     *
     * - the `_totalSupply` should not transcend `_maxSupply` after the new token is generated
     * - `msgValue` should be greater or equal to `_pricePerMint`
     * 
     * @param   to           target address
     * @return  nextToken    next id for this newly minted token
     */
    function beforeMint(address to) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s._totalSupply == s._maxSupply) revert RMRKMintOverMax();
        if (LibMeta._msgValue() < s._pricePerMint) revert RMRKMintUnderpriced();
        uint256 nextToken = s._totalSupply + 1;
        unchecked {
            s._totalSupply += 1;
        }

        return nextToken;
    }

    /**
     * @notice Used for safely minting a new NFT, giving a ERC-721 check when the receiver is a contract
     * @dev requirements:
     *
     * - If the target address `to` is a contract, it should be aware of ERC-721 protocol to prevent this token is permanently locked
     *
     * @param to        Address to which to mint the token
     * @param tokenId   ID of the token to mint
     * @param data      Additional data to send with the tokens
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId, data);

        if (!LibERC721._checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to mint a specified token to a given address.
     * @dev WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible.
     * @dev Requirements:
     *
     *  - `tokenId` must not exist.
     *  - `to` cannot be the zero address.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param to Address to mint the token to
     * @param tokenId ID of the token to mint
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _mint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        if (LibNestable._exists(tokenId)) revert ERC721TokenAlreadyMinted();
        if (tokenId == 0) revert RMRKIdZeroForbidden();

        AppStorage storage s = LibAppStorage.diamondStorage();
        s._balances[to] += 1;
        s.owner[tokenId] = to;

        emit LibERC721.Transfer(address(0), to, tokenId);
        emit LibNestable.NestTransfer(address(0), to, 0, 0, tokenId);
    }
}