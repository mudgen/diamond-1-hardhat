/* eslint prefer-const: "off" */
const hre = require("hardhat");
const ethers = hre.ethers;

async function deployTracker (diamond) {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // Setting arguments that will be used in the diamond constructor
  const trackerArgs = {
    diamondTarget: diamond,
    owner: contractOwner.address
  }

  // deploy Diamond
  const Tracker = await ethers.getContractFactory('Tracker')
  const tracker = await Tracker.deploy(trackerArgs)
  await tracker.deployed()
  console.log()
  console.log('Tracker deployed:', tracker.address)

  // returning the address of the tracker
  return tracker.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployTracker(...process.argv.slice(2))
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployTracker = deployTracker
