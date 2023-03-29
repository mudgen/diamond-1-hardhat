// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.16;

import { LibOwnership } from "./LibOwnership.sol";
import {ERC721TransferFromIncorrectOwner, ERC721TransferToNonReceiverImplementer,ERC721TransferToTheZeroAddress } from "../../shared/RMRKErrors.sol";
import { LibAppStorage, AppStorage } from "../../storage/LibAppStorage.sol";
import { LibERC721 } from "../../libraries/LibERC721.sol";

library LibTransfer {

    /**
     * @notice Used to safely transfer the token form `from` to `to`.
     * @dev The function checks that contract recipients are aware of the ERC721 protocol to prevent tokens from being
     *  forever locked.
     * @dev This internal function is equivalent to {safeTransferFrom}, and can be used to e.g. implement alternative
     *  mechanisms to perform token transfer, such as signature-based.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal  {
        _transfer(from, to, tokenId, data);
        if (!LibERC721._checkOnERC721Received(from, to, tokenId, data)) revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to transfer the token from `from` to `to`.
     * @dev As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must be owned by `from`.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _transfer(address from, address to, uint256 tokenId, bytes memory data) internal  {
        // only owner of will solve the minting & transfer here
        address owner = LibOwnership.ownerOf(tokenId);
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (owner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        s._balances[from] -= 1;
        LibOwnership.removeOwnership(from, tokenId);
        LibOwnership._updateOwnerAndClearApprovals(tokenId, to);
        s._balances[to] += 1;
        LibOwnership.confirmOwnership(to, tokenId);

        emit LibERC721.Transfer(from, to, tokenId);
    }
}