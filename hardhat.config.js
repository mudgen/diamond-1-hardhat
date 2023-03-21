const { task } = require('hardhat/config')

/* global ethers task */
require('@nomiclabs/hardhat-waffle')
require("dotenv").config()
require("@nomiclabs/hardhat-ethers")
require("hardhat-deploy")

const { ALCHEMY_API_URL, PRIVATE_KEY } = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: '0.8.16',
  settings: {
    optimizer: {
      enabled: true,
      runs: 1000000
    },
    mocha: {
      timeout: 90000
    },
    networks: {
      hardhat: {
        initialBaseFeePerGas: 0,
        blockGasLimit: 18800000,
      },
      mumbai: {
        url: ALCHEMY_API_URL,
        accounts: [`0x${PRIVATE_KEY}`]
      }
    },
    namedAccounts: {
      deployer: 0
    },
  }
}
