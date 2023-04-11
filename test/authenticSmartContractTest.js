const { assert, expect } = require('chai')
const { ethers, waffle } = require('hardhat')

const { deployAuthenticSCManager } = require('../scripts/deployAuthenticSC.js')

describe('authenticSmartContractTest', async function() {

    let authenticSCManagerAddress

    // contract instance
    let authenticSCManager

    before(async function () {
        authenticSCManagerAddress = await deployAuthenticSCManager()
        authenticSCManager = await ethers.getContractAt('AuthenticateSCManager', authenticSCManagerAddress)
    })

    it('should fail on adding authenticate smart contract when current operator is not the owner', async() => {
        const accounts = await ethers.getSigners()
        const currentOperator = accounts[1]

        const smartContractAddress = '0xdb211f4CB3d1a3BC904e47f7A7c7932312ABD24a'

        await expect(authenticSCManager.connect(currentOperator).register(smartContractAddress, 1))
                .to.be.revertedWith('Ownable: caller is not the owner')
    })

    it('should fail on adding authenticate smart contract when parameter is invalid', async() => {
        const smartContractAddress = '0xdb211f4CB3d1a3BC904e47f7A7c7932312ABD24a'

        await expect(authenticSCManager.register(smartContractAddress, 0))
                .to.be.revertedWith('max active num should be greater than 0')
        
        await expect(authenticSCManager.register(ethers.constants.AddressZero, 1))
                .to.be.revertedWith('invalid contract address')
    })

    it('should success on adding authenticate smart contract when current operator is the contract owner', async() => {
        
        const smartContractAddress = '0xdb211f4CB3d1a3BC904e47f7A7c7932312ABD24a'
        
        await authenticSCManager.register(smartContractAddress, 1)
        const {authentic, maxActiveNum} = await authenticSCManager.authenticated(smartContractAddress)

        assert.isTrue(authentic)
        assert.equal(maxActiveNum, 1)

    })

    it('should fail on deleting authenticated smart contract when current operator is not the contract owner', async() => {
        const smartContractAddress = '0xdb211f4CB3d1a3BC904e47f7A7c7932312ABD24a'

        const accounts = await ethers.getSigners()
        const currentOperator = accounts[1]

        await expect(authenticSCManager.connect(currentOperator).remove(smartContractAddress))
                .to.be.revertedWith('Ownable: caller is not the owner')
    })

    it('should successfully remove authenticate smart contract', async() => {
        const smartContractAddress = '0xdb211f4CB3d1a3BC904e47f7A7c7932312ABD24a'
        
        await authenticSCManager.register(smartContractAddress, 1)

        let result = await authenticSCManager.authenticated(smartContractAddress)

        assert.isTrue(result.authentic)
        assert.equal(result.maxActiveNum, 1)

        // start deleting authenticated smart contract
        await authenticSCManager.remove(smartContractAddress)
        result = await authenticSCManager.authenticated(smartContractAddress)


        assert.isFalse(result.authentic)
        assert.equal(result.maxActiveNum, 0)
    })
})