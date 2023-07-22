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

async function setTrustedRemotesFromGoerliToMumbai() {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];

    const ONFT = await ethers.getContractFactory('ONFT721', diamondAddressB);

    // Attach to diamond contract
    const oNFT721 = await ONFT.attach(diamondAddressB);

    // set each contracts source address so it can send to each other
    await oNFT721.setTrustedRemote(
        chainId_A,
        ethers.utils.solidityPack(['address', 'address'], [diamondAddressA, diamondAddressB])
    );
}

setTrustedRemotesFromGoerliToMumbai();
