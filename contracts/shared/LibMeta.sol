

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.16;

library LibMeta {

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view returns (uint256) {
        return msg.value;
    }
}