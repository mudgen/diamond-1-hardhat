/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')

const { assert, expect } = require('chai')
const { ethers, waffle } = require('hardhat')

describe('DiamondTest', async function () {
  let diamondAddress
  let diamondCutFacet
  let diamondLoupeFacet
  let ownershipFacet
  let tx
  let receipt
  let result
  const addresses = []
  let baseInfoFacet
  let collectionMetaFacet
  let royaltyInfoFacet
  let mintAndBurnFacet
  let rmrkNestableFacet
  
  // libraries
  let libERC721
  let libRMRKNestable

  // provider
  let provider


  before(async function () {
    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
    baseInfoFacet = await ethers.getContractAt('BaseInfoFacet', diamondAddress)
    collectionMetaFacet = await ethers.getContractAt('CollectionMetaFacet', diamondAddress)
    royaltyInfoFacet = await ethers.getContractAt('RoyaltyInfoFacet', diamondAddress)
    mintAndBurnFacet = await ethers.getContractAt('RMRKMintAndBurnFacet', diamondAddress)
    rmrkNestableFacet = await ethers.getContractAt('RMRKNestableFacet', diamondAddress)

    libERC721 = await ethers.getContractFactory('LibERC721')
    libRMRKNestable = await ethers.getContractFactory('LibNestable')

    provider = waffle.provider
  })

  it('should have nine facets -- call to facetAddresses function', async () => {
    for (const address of await diamondLoupeFacet.facetAddresses()) {
      addresses.push(address)
    }

    assert.equal(addresses.length, 9)
  })

  it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
    let selectors = getSelectors(diamondCutFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(diamondLoupeFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(ownershipFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2])
    assert.sameMembers(result, selectors)
  })

  it('selectors should be associated to facets correctly -- multiple calls to facetAddress function', async () => {
    assert.equal(
      addresses[0],
      await diamondLoupeFacet.facetAddress('0x1f931c1c')
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
      addresses[2],
      await diamondLoupeFacet.facetAddress('0xf2fde38b')
    )
  })

  it('should get correct base info', async () => {
    const name = await baseInfoFacet.name()
    const symbol = await baseInfoFacet.symbol()

    assert.equal(name, 'NAIN NFT', 'incorrect NFT name')
    assert.equal(symbol, 'NAIN', 'incorrect NFT symbol')
  })

  it('should get correct collection meta info', async () => {
    const collecionMetaUrl = await collectionMetaFacet.collectionMetadata()
    const tokenUri = await collectionMetaFacet.tokenURI(23)

    assert.equal(collecionMetaUrl, 'https://project-oracle-test.mypinata.cloud/ipfs/bafkreihnix2zvskkwdkxb2icb43j42f6yflc5kdotrmzdmk6nlqmqxjwma')
    assert.equal(tokenUri, 'https://project-oracle-test.mypinata.cloud/ipfs/QmRxFwKofDa8hebvQMXT8eU8xzck35gN9aRrY75H5eoDiz/7.png')
  })

  it('should get correct royalty info', async () => {
    const royaltyReceipient = await royaltyInfoFacet.getRoyaltyRecipient()
    const royaltyPercentage = await royaltyInfoFacet.getRoyaltyPercentage()
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]
    const contractOwnerAddress = await contractOwner.getAddress()
    
    assert.equal(royaltyReceipient, contractOwnerAddress)
    assert.equal(royaltyPercentage, 2)
  })

  // mint a new nestable NFT - should not mint under price
  it('should not mint under price', async () => {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]
    const contractOwnerAddress = await contractOwner.getAddress()
    const payValue = ethers.utils.parseUnits("0.001","ether")
    await expect(mintAndBurnFacet.mint(contractOwnerAddress, {value: payValue})).to.be.revertedWith('RMRKMintUnderpriced')
  })

  // mint a new nestable NFT - should not mint to zero address
  it('should not mint to zero address', async () => {
    const payValue = ethers.utils.parseUnits("0.01","ether")
    await expect(mintAndBurnFacet.mint(ethers.constants.AddressZero, {value: payValue})).to.be.revertedWith('ERC721MintToTheZeroAddress')
  })

  // mint a new nestable NFT - should success
  it('should successfully mint a new NFT', async () => {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]
    const contractOwnerAddress = await contractOwner.getAddress()
    const payValue = ethers.utils.parseUnits("0.01","ether")

    await expect(mintAndBurnFacet.mint(contractOwnerAddress, {value: payValue}))
      .to.emit(libERC721.attach(mintAndBurnFacet.address), 'Transfer').withArgs(ethers.constants.AddressZero, contractOwnerAddress, 1)
      .to.emit(libRMRKNestable.attach(mintAndBurnFacet.address), 'NestTransfer').withArgs(ethers.constants.AddressZero, contractOwnerAddress, 0, 0, 1)

    // check balance
    const contractBalance = await provider.getBalance(diamondAddress)
    assert.equal(contractBalance.value, payValue.value)

    // check max supply
    const maxSupply = await baseInfoFacet.maxSupply()
    assert.equal(maxSupply, 999)

    // check owner's balance
    const balance = await rmrkNestableFacet.balanceOf(contractOwnerAddress)
    assert.equal(1, balance)
  })

})
