/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')
const { deployTracker } = require('../scripts/deployTracker.js')

const { assert } = require('chai');
const { ethers } = require('hardhat');


describe('TrackerTest', async function () {
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

  before(async function () {
    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
    trackerAddress = await deployTracker(diamondAddress)
    tracker = await ethers.getContractAt('Tracker', trackerAddress)
    trackerLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', trackerAddress)
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

    assert.equal(trackerAddresses.length, 3)
    assert.equal(trackerAddresses[0], addresses[0])
    assert.equal(trackerAddresses[1], addresses[1])
    assert.equal(trackerAddresses[2], addresses[2])
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

    assert.equal(
      addresses[1],
      await diamondLoupeFacet.facetAddress('0xcdffacc6')
    )
    assert.equal(
      addresses[1],
      await diamondLoupeFacet.facetAddress('0x01ffc9a7')
    )

    assert.equal(
      addresses[1],
      await trackerLoupeFacet.facetAddress('0xcdffacc6')
    )
    assert.equal(
      addresses[1],
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

  //---------------------------------------------
  // Subsequent tests act on behalf of the diamond *target* operator (the
  // beacon), then check that the user sees the effects through their tracker
  //---------------------------------------------

  it('should add test1 functions', async () => {

    // Note: this shows that the tracker 'follows' the diamond beacon when it is upgraded by its operator.
    const Test1Facet = await ethers.getContractFactory('Test1Facet')
    const test1Facet = await Test1Facet.deploy()
    await test1Facet.deployed()
    addresses.push(test1Facet.address)
    const selectors = getSelectors(test1Facet).remove(['supportsInterface(bytes4)'])
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: test1Facet.address,
        action: FacetCutAction.Add,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    result = await diamondLoupeFacet.facetFunctionSelectors(test1Facet.address)
    assert.sameMembers(result, selectors)
    result = await trackerLoupeFacet.facetFunctionSelectors(test1Facet.address)
    assert.sameMembers(result, selectors)
  })

  it('should test function call', async () => {
    const test1Facet = await ethers.getContractAt('Test1Facet', trackerAddress)
    await test1Facet.test1Func10()
  })

  it('should replace supportsInterface function', async () => {
    const Test1Facet = await ethers.getContractFactory('Test1Facet')
    const selectors = getSelectors(Test1Facet).get(['supportsInterface(bytes4)'])
    const testFacetAddress = addresses[3]
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: testFacetAddress,
        action: FacetCutAction.Replace,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    result = await diamondLoupeFacet.facetFunctionSelectors(testFacetAddress)
    assert.sameMembers(result, getSelectors(Test1Facet))
    result = await trackerLoupeFacet.facetFunctionSelectors(testFacetAddress)
    assert.sameMembers(result, getSelectors(Test1Facet))
  })

  it('should add test2 functions', async () => {
    const Test2Facet = await ethers.getContractFactory('Test2Facet')
    const test2Facet = await Test2Facet.deploy()
    await test2Facet.deployed()
    addresses.push(test2Facet.address)
    const selectors = getSelectors(test2Facet)
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: test2Facet.address,
        action: FacetCutAction.Add,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    result = await diamondLoupeFacet.facetFunctionSelectors(test2Facet.address)
    assert.sameMembers(result, selectors)

    result = await trackerLoupeFacet.facetFunctionSelectors(test2Facet.address)
    assert.sameMembers(result, selectors)
  })

  it('should remove some test2 functions', async () => {
    const test2Facet = await ethers.getContractAt('Test2Facet', diamondAddress)
    const functionsToKeep = ['test2Func1()', 'test2Func5()', 'test2Func6()', 'test2Func19()', 'test2Func20()']
    const selectors = getSelectors(test2Facet).remove(functionsToKeep)
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: ethers.constants.AddressZero,
        action: FacetCutAction.Remove,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[4])
    assert.sameMembers(result, getSelectors(test2Facet).get(functionsToKeep))

    result = await trackerLoupeFacet.facetFunctionSelectors(addresses[4])
    assert.sameMembers(result, getSelectors(test2Facet).get(functionsToKeep))
  })

  it('should remove some test1 functions', async () => {
    const test1Facet = await ethers.getContractAt('Test1Facet', diamondAddress)
    const functionsToKeep = ['test1Func2()', 'test1Func11()', 'test1Func12()']
    const selectors = getSelectors(test1Facet).remove(functionsToKeep)
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: ethers.constants.AddressZero,
        action: FacetCutAction.Remove,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3])
    assert.sameMembers(result, getSelectors(test1Facet).get(functionsToKeep))

    result = await trackerLoupeFacet.facetFunctionSelectors(addresses[3])
    assert.sameMembers(result, getSelectors(test1Facet).get(functionsToKeep))

  })

  it('remove all functions and facets accept \'diamondCut\' and \'facets\'', async () => {
    let selectors = []
    let facets = await diamondLoupeFacet.facets()
    for (let i = 0; i < facets.length; i++) {
      selectors.push(...facets[i].functionSelectors)
    }
    selectors = removeSelectors(selectors, ['facets()', 'diamondCut(tuple(address,uint8,bytes4[])[],address,bytes)'])
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: ethers.constants.AddressZero,
        action: FacetCutAction.Remove,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    let diamondFacets = await diamondLoupeFacet.facets()
    let trackerFacets = await trackerLoupeFacet.facets()

    for (const facets of [diamondFacets, trackerFacets]) {
      assert.equal(facets.length, 2)
      assert.equal(facets[0][0], addresses[0])
      assert.sameMembers(facets[0][1], ['0x1f931c1c'])
      assert.equal(facets[1][0], addresses[1])
      assert.sameMembers(facets[1][1], ['0x7a0ed627'])
    }
  })

  it('add most functions and facets', async () => {
    const diamondLoupeFacetSelectors = getSelectors(diamondLoupeFacet).remove(['supportsInterface(bytes4)'])
    const Test1Facet = await ethers.getContractFactory('Test1Facet')
    const Test2Facet = await ethers.getContractFactory('Test2Facet')
    // Any number of functions from any number of facets can be added/replaced/removed in a
    // single transaction
    const cut = [
      {
        facetAddress: addresses[1],
        action: FacetCutAction.Add,
        functionSelectors: diamondLoupeFacetSelectors.remove(['facets()'])
      },
      {
        facetAddress: addresses[2],
        action: FacetCutAction.Add,
        functionSelectors: getSelectors(ownershipFacet)
      },
      {
        facetAddress: addresses[3],
        action: FacetCutAction.Add,
        functionSelectors: getSelectors(Test1Facet)
      },
      {
        facetAddress: addresses[4],
        action: FacetCutAction.Add,
        functionSelectors: getSelectors(Test2Facet)
      }
    ]
    tx = await diamondCutFacet.diamondCut(cut, ethers.constants.AddressZero, '0x', { gasLimit: 8000000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }

    let diamondFacets = await diamondLoupeFacet.facets()
    let diamondFacetAddresses = await diamondLoupeFacet.facetAddresses()
    let trackerFacets = await trackerLoupeFacet.facets()
    let trackerFacetAddresses = await trackerLoupeFacet.facetAddresses()

    for (const [facets, facetAddresses] of [[diamondFacets, diamondFacetAddresses], [trackerFacets, trackerFacetAddresses]]) {
      assert.equal(facetAddresses.length, 5)
      assert.equal(facets.length, 5)
      assert.sameMembers(facetAddresses, addresses)
      assert.equal(facets[0][0], facetAddresses[0], 'first facet')
      assert.equal(facets[1][0], facetAddresses[1], 'second facet')
      assert.equal(facets[2][0], facetAddresses[2], 'third facet')
      assert.equal(facets[3][0], facetAddresses[3], 'fourth facet')
      assert.equal(facets[4][0], facetAddresses[4], 'fifth facet')
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[0], facets)][1], getSelectors(diamondCutFacet))
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[1], facets)][1], diamondLoupeFacetSelectors)
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[2], facets)][1], getSelectors(ownershipFacet))
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[3], facets)][1], getSelectors(Test1Facet))
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[4], facets)][1], getSelectors(Test2Facet))
    }
  })
});