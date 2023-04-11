// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@rmrk-team/evm-contracts/contracts/implementations/nativeTokenPay/RMRKNestableImpl.sol";

contract ConcertEventTicket is RMRKNestableImpl {
    
    constructor(InitData memory data)
        RMRKNestableImpl(
            "VIP Concert Ticket",
            "VCT",
            "https://project-oracle-test.mypinata.cloud/ipfs/bafkreihirqsm42hgprmf7sbqkhtzzjyf3lje7egc3k3gtxroqotgu262lu",
            "https://project-oracle-test.mypinata.cloud/ipfs/bafkreigby7f6vpmu6zyosdgmaagkdzx2gocuiqhphgbvbdnuz7qtsamena",
            data
        )
    {    }

    function contractURI() public view returns (string memory) {
        return this.collectionMetadata();
    }
}