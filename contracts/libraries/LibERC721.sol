// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import { LibMeta } from "../shared/LibMeta.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../shared/RMRKErrors.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library LibERC721 {

    using Address for address;

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);


    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////


    /**
     * @notice Used to invoke {IERC721Receiver-onERC721Received} on a target address.
     * @dev The call is not executed if the target address is not a contract.
     * @param from Address representing the previous owner of the given token
     * @param to Yarget address that will receive the tokens
     * @param tokenId ID of the token to be transferred
     * @param data Optional data to send along with the call
     * @return Boolean value signifying whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(LibMeta._msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
