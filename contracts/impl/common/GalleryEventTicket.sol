// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@rmrk-team/evm-contracts/contracts/implementations/nativeTokenPay/RMRKNestableImpl.sol";

contract GalleryEventTicket is RMRKNestableImpl {
    
    constructor(InitData memory data)
        RMRKNestableImpl(
            "Exclusive Experience",
            "EEx",
            "https://project-oracle-test.mypinata.cloud/ipfs/bafkreifnxvlokawjd6qupmb2fwh2bwtaudz3dfkngjrgneuf23uyl7fub4",
            "https://project-oracle-test.mypinata.cloud/ipfs/bafkreihalvnukt7czf7rzkhpel3os3ugznfztycdg376tixenut5izho2u",
            data
        )
    {    }

    function contractURI() public view returns (string memory) {
        return this.collectionMetadata();
    }
}