/* global ethers task */
require('@nomiclabs/hardhat-waffle');
require('dotenv').config();
require('@nomicfoundation/hardhat-verify');
require('hardhat-contract-sizer');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
    const accounts = await ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: '0.8.17',
    settings: {
        optimizer: {
            enabled: true,
            runs: 200,
        },
    },
    gasReporter: {
        enabled: true,
        currency: 'USD',
        gasPrice: 21,
        url: 'http://localhost:8545',
    },
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
        },
        goerli: {
            url: `https://eth-goerli.g.alchemy.com/v2/${process.env.GOERLI_ALCHEMY_API_KEY}`,
            accounts: [process.env.GOERLI_PRIVATE_KEY],
        },
        'mumbai-testnet': {
            url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.MUMBAI_ALCHEMY_API_KEY}`,
            accounts: [process.env.MUMBAI_PRIVATE_KEY],
        },
        'polygonzkevm-testnet': {
            url: `https://polygonzkevm-testnet.g.alchemy.com/v2/${process.env.POLYGONZKEVM_ALCHEMY_API_KEY}`,
            accounts: [process.env.POLYGONZKEVM_TESTNET_PRIVATE_KEY],
        },
    },
    // You must manually swap out API keys when verifying contracts
    etherscan: {
        apiKey: process.env.POLYGONSCAN_API_KEY,
    },
    polygonscan: {
        apiKey: process.env.POLYGONSCAN_API_KEY,
    },
    contractSizer: {
        alphaSort: true,
        disambiguatePaths: false,
        runOnCompile: true,
        strict: true,
        // only: [':ERC20$'],
    },
};
