const { ethers } = require("hardhat");

async function deployTicketNFT() {

  const pricePerMint = ethers.utils.parseEther('0.001');
  // Define the constructor arguments
  const initData = {
    erc20TokenAddress: "0x0000000000000000000000000000000000001010",
    tokenUriIsEnumerable: false,
    royaltyRecipient: "0xA0AFCFD57573C211690aA8c43BeFDfC082680D58",
    royaltyPercentageBps: 2,
    maxSupply: 8,
    pricePerMint: pricePerMint
  };

  // Deploy the contract
  const GalleryEventTicket = await ethers.getContractFactory("GalleryEventTicket");
  const galleryEventTicket = await GalleryEventTicket.deploy(
    initData
  );

  await galleryEventTicket.deployed();

  console.log(`gallery ticket contract deployed to: ${galleryEventTicket.address}`);

  const ConcertEventTicket = await ethers.getContractFactory("ConcertEventTicket");
  const concertEventTicket = await ConcertEventTicket.deploy(
    initData
  );
  await concertEventTicket.deployed();

  console.log(`concert ticket contract deployed to: ${concertEventTicket.address}`);

  return {
    galleryEventTicket: galleryEventTicket.address,
    concertEventTicket: concertEventTicket.address
  }
}

if (require.main === module) {
    deployDiamond()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }

exports.deployTicketNFT = deployTicketNFT

