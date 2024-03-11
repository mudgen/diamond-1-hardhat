/* eslint prefer-const: "off" */

// Use the hre explicitly so we can run scripts as plain node scripts/xxx.js and
// pass in arguments (which isn't possible via npx hardhat run)
const hre = require("hardhat");
const ethers = hre.ethers;

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function deployDiamondTracker (targetDiamond) {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // Deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
  // Read about how the diamondCut function works in the EIP2535 Diamonds standard
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)

  // Deploy facets and set the `facetCuts` variable
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondTrackerLoupeFacet',
    // 'OwnershipFacet' -> target diamond
  ]
  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    facetCuts.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  // Creating a function call
  // This call gets executed during deployment and can also be executed in upgrades
  // It is executed with delegatecall on the DiamondInit address.
  let functionCall = diamondInit.interface.encodeFunctionData('init')

  // Setting arguments that will be used in the diamond constructor
  const diamondArgs = {
    diamondTarget: targetDiamond,
    owner: contractOwner.address,
    init: diamondInit.address,
    initCalldata: functionCall
  }

  // deploy Diamond
  const DiamondTracker = await ethers.getContractFactory('DiamondTracker')
  const diamondTracker = await DiamondTracker.deploy(facetCuts, diamondArgs)
  await diamondTracker.deployed()
  console.log()
  console.log('DiamondTracker deployed:', diamondTracker.address)

  // returning the address of the diamond
  return diamondTracker.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamondTracker(...process.argv.slice(2))
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamondTracker = deployDiamondTracker
