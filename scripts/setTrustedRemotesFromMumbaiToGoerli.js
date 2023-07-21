/* global ethers */
/* eslint prefer-const: "off" */

const {ethers} = require('hardhat');
require('dotenv').config();

const diamondAddressA = process.env.DIAMOND_CONTRACT_ADDRESS_MUMBAI;
const diamondAddressB = process.env.DIAMOND_CONTRACT_ADDRESS_GOERLI;

// Mumbai
const chainId_A = process.env.CHAIN_A;
// Goerli
const chainId_B = process.env.CHAIN_B;

async function setTrustedRemotesFromMumbaiToGoerli() {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];

    const ERC721AUpgradeable = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressA);

    // Attach to diamond contract
    const eRC721AUpgradeable = await ERC721AUpgradeable.attach(diamondAddressA);

    // set each contracts source address so it can send to each other
    await eRC721AUpgradeable.setTrustedRemote(
        chainId_B,
        ethers.utils.solidityPack(['address', 'address'], [diamondAddressB, diamondAddressA])
    );
}

setTrustedRemotesFromMumbaiToGoerli();
