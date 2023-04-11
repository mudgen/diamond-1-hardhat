/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')
const { deployTicketNFT } = require('../scripts/deployTicketNFT.js')

const { assert, expect } = require('chai')
const { ethers, waffle } = require('hardhat')

describe('DiamondTest', async function () {

  // authentic smart contract 
  // diamond facets
  let diamondAddress
  let authenticateSCManagerAddress
  let authenticateSCManager
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

  // tickets demo
  let galleryEventTicketAddress;
  let galleryEventTicket;
  let concertEventTicketAddress;
  let concertEventTicket;

  // provider
  let provider


  before(async function () {

    let ticketDeployResult = await deployTicketNFT()
    galleryEventTicketAddress = ticketDeployResult.galleryEventTicket
    concertEventTicketAddress = ticketDeployResult.concertEventTicket


    let result = await deployDiamond()
    diamondAddress = result.diamondAddress
    authenticateSCManagerAddress = result.scManagerAddress
    authenticateSCManager = await ethers.getContractAt('AuthenticateSCManager', authenticateSCManagerAddress)
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
    const scManagerAddress = await baseInfoFacet.authenticateSCManagerAddress()

    assert.equal(name, 'NAIN NFT', 'incorrect NFT name')
    assert.equal(symbol, 'NAIN', 'incorrect NFT symbol')
    assert.equal(scManagerAddress, authenticateSCManagerAddress, 'incorrect sc manager address')
  })

  it('should get correct collection meta info', async () => {
    const collecionMetaUrl = await collectionMetaFacet.collectionMetadata()
    const tokenUri = await collectionMetaFacet.tokenURI(15)

    assert.equal(collecionMetaUrl, 'https://project-oracle-test.mypinata.cloud/ipfs/bafkreidbr7q2hxxsviaks6jrgz4aaicek5ylv5otwdq3v4u2l5op6yc4sq')
    assert.equal(tokenUri, 'https://project-oracle-test.mypinata.cloud/ipfs/QmWUhDtzYcyqovbkefa2oR19fnB4MTk2AC8W6xkY1EBoRv/15')
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
    assert.equal(maxSupply, 16)

    // check owner's balance
    const balance = await rmrkNestableFacet.balanceOf(contractOwnerAddress)
    assert.equal(1, balance)

    // check get token uri by index
    const {tokenId, tokenUri} = await rmrkNestableFacet.getOwnerCollectionByIndex(contractOwnerAddress, 0)
    assert.equal(1, tokenId)
    assert.equal("https://project-oracle-test.mypinata.cloud/ipfs/QmWUhDtzYcyqovbkefa2oR19fnB4MTk2AC8W6xkY1EBoRv/1", tokenUri)
  })

  it('should successfully register gallery ticket and try to add it into main NFT collection', async() => {
    // 1. try to deploy Gallery event ticket
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
    const GalleryEventTicket = await ethers.getContractFactory('GalleryEventTicket')
    const gallertEventTicket = await GalleryEventTicket.deploy(initData)
    await gallertEventTicket.deployed()

    // 2. try to add authenticate smart contract address to authenticateSCManager
    await authenticateSCManager.register(gallertEventTicket.address, 1)

    // 3. try to add this ticket as a child NFT into main NFT's collection
    const payValue = ethers.utils.parseUnits("0.001","ether")
    await expect(gallertEventTicket.nestMint(diamondAddress, 1, 1, {value: payValue}))
      .to.emit(libRMRKNestable.attach(diamondAddress), 'ChildAccepted')
      .withArgs(1, 0, gallertEventTicket.address, 1);

    // 4. check tokenId:1 's child NFT collection
    console.log('check tokneId 1\'s child NFT collection...')
    const child = await rmrkNestableFacet.childrenOf(1);
    assert.equal(1, child.length)
    assert.equal(child[0].contractAddress, gallertEventTicket.address)
    assert.equal(child[0].tokenId, 1)

    // 5. check child NFT's token url
    console.log('check tokneId 1\'s token Uri')
    const tokenUri = await gallertEventTicket.tokenURI(child[0].tokenId)
    assert.equal(tokenUri, 'https://project-oracle-test.mypinata.cloud/ipfs/bafkreihalvnukt7czf7rzkhpel3os3ugznfztycdg376tixenut5izho2u')

    // 6. try to add one more, it should go to the pending child array, emitting `ChildProposed` event
    console.log('try adding one more NFT, should be in pending children queue')
    await expect(gallertEventTicket.nestMint(diamondAddress, 1, 1, {value: payValue}))
      .to.emit(libRMRKNestable.attach(diamondAddress), 'ChildProposed')
      .withArgs(1, 0, gallertEventTicket.address, 2);
    
    // 7. check pending child NFTs
    console.log('checking pending children queue...')
    const pendingChildren = await rmrkNestableFacet.pendingChildrenOf(1)
    assert.equal(pendingChildren.length, 1)
    assert.equal(pendingChildren[0].contractAddress, gallertEventTicket.address)
    assert.equal(pendingChildren[0].tokenId, 2)
  })

  it('should directly be added into pending children for not authenticated NFT', async () => {
      // 1. try to deploy Gallery event ticket
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
      const ConcertEventTicket = await ethers.getContractFactory('ConcertEventTicket')
      const concertEventTicket = await ConcertEventTicket.deploy(initData)
      await concertEventTicket.deployed()

      const payValue = ethers.utils.parseUnits("0.001","ether")
      // we have minted a pending child before, so the initial length of this event should be 1
      await expect(concertEventTicket.nestMint(diamondAddress, 1, 1, {value: payValue}))
        .to.emit(libRMRKNestable.attach(diamondAddress), 'ChildProposed')
        .withArgs(1, 1, concertEventTicket.address, 1);
      
      
      const pendingChildren = await rmrkNestableFacet.pendingChildrenOf(1)
      assert.equal(pendingChildren.length, 2)
      assert.equal(pendingChildren[1].contractAddress, concertEventTicket.address)
      assert.equal(pendingChildren[1].tokenId, 1)

      // query the newly minted tokenUri
      const tokenUri = await concertEventTicket.tokenURI(pendingChildren[1].tokenId)
      assert.equal(tokenUri, 'https://project-oracle-test.mypinata.cloud/ipfs/bafkreigby7f6vpmu6zyosdgmaagkdzx2gocuiqhphgbvbdnuz7qtsamena')
  })

})
