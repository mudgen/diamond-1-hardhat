/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')

async function deployAuthenticSCManager() {
    
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]

    const AuthenticSCManager = await ethers.getContractFactory('AuthenticateSCManager')
    const authenticSCManager = await AuthenticSCManager.deploy()

    await authenticSCManager.deployed()

    console.log(`authenticSCManager deployed: ${authenticSCManager.address}`)

    return authenticSCManager.address

}

if (require.main === module) {
    deployAuthenticSCManager()
        .then((address) => {return address})
        .catch(error => {
            console.error(error)
            process.exit(1)
    })
}

exports.deployAuthenticSCManager = deployAuthenticSCManager
