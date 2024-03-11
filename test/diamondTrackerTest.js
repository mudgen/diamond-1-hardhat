/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')
const { deployDiamondTracker } = require('../scripts/deployDiamondTracker.js')
const { assert } = require('chai');
const { ethers } = require('hardhat');


describe('DiamondTrackerTest', async function () {
  let diamondAddress
  let diamondCutFacet
  let diamondLoupeFacet
  let ownershipFacet
  let trackerAddress
  let tracker
  let trackerLoupeFacet
  let tx
  let receipt
  let result
  const addresses = []
  const trackerAddresses = []
  const firstTargetFacet = 1;

  before(async function () {
    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
    trackerAddress = await deployDiamondTracker(diamondAddress)
                           
    tracker = await ethers.getContractAt('DiamondTracker', trackerAddress)
    trackerLoupeFacet = await ethers.getContractAt('DiamondTrackerLoupeFacet', trackerAddress)
  })

  it('Should have three facets on Diamond -- call to facetAddresses function', async () => {
    for (const address of await diamondLoupeFacet.facetAddresses()) {
      addresses.push(address)
    }

    assert.equal(addresses.length, 3)
  })

  it('Should see same three facets via Tracker -- call to Tracker.facetAddresses function', async () => {
    for (const address of await trackerLoupeFacet.facetAddresses()) {
      trackerAddresses.push(address)
    }

    assert.equal(trackerAddresses.length, firstTargetFacet + 3)
    assert.equal(trackerAddresses[firstTargetFacet + 0], addresses[0])
    assert.equal(trackerAddresses[firstTargetFacet + 1], addresses[1])
    assert.equal(trackerAddresses[firstTargetFacet + 2], addresses[2])
  })

  it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
    let selectors = getSelectors(diamondCutFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
    assert.sameMembers(result, selectors)
    result = await trackerLoupeFacet.facetFunctionSelectors(addresses[0])
    assert.sameMembers(result, selectors)

    selectors = getSelectors(diamondLoupeFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
    assert.sameMembers(result, selectors)
    result = await trackerLoupeFacet.facetFunctionSelectors(addresses[1])
    assert.sameMembers(result, selectors)

    selectors = getSelectors(ownershipFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2])
    assert.sameMembers(result, selectors)
    result = await trackerLoupeFacet.facetFunctionSelectors(addresses[2])
    assert.sameMembers(result, selectors)
  })

  it('selectors should be associated to facets correctly -- multiple calls to facetAddress function', async () => {
    assert.equal(
      addresses[0],
      await diamondLoupeFacet.facetAddress('0x1f931c1c')
    )
    assert.equal(
      addresses[0],
      await trackerLoupeFacet.facetAddress('0x1f931c1c')
    )

    // The DiamondTracker has its own implementation of IDiamondLouper and that is in facet slot 1
    assert.equal(
      addresses[1],
      await diamondLoupeFacet.facetAddress('0xcdffacc6')
    )
    assert.equal(
      addresses[1],
      await diamondLoupeFacet.facetAddress('0x01ffc9a7')
    )

    assert.notEqual(
      addresses[1],
      await trackerLoupeFacet.facetAddress('0xcdffacc6')
    )

    // The tracker has one implementation facet and its in position 0. it
    // implements IDiamondLoupe. This OVERRIDES the implementation in the target
    // diamond
    assert.equal(
      trackerAddresses[0],
      await trackerLoupeFacet.facetAddress('0xcdffacc6')
    )

    assert.notEqual(
      addresses[1],
      await trackerLoupeFacet.facetAddress('0x01ffc9a7')
    )
    assert.equal(
      trackerAddresses[0],
      await trackerLoupeFacet.facetAddress('0x01ffc9a7')
    )

    assert.equal(
      addresses[2],
      await diamondLoupeFacet.facetAddress('0xf2fde38b')
    )
    assert.equal(
      addresses[2],
      await trackerLoupeFacet.facetAddress('0xf2fde38b')
    )
  })


});