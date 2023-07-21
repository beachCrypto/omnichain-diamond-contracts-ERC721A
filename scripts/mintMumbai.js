/* global ethers */
/* eslint prefer-const: "off" */

const {ethers} = require('hardhat');
require('dotenv').config();
const mintFacet = require('../artifacts/contracts/facets/MintFacet.sol/MintFacet.json');

const diamondAddressA = process.env.DIAMOND_CONTRACT_ADDRESS_MUMBAI;

async function mintOnMumbai() {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];

    const MintFacet = await ethers.getContractFactory('MintFacet');

    const mintFacet = await MintFacet.attach(diamondAddressA);

    await mintFacet.mint(500);
}
mintOnMumbai();
