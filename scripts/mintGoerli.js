/* global ethers */
/* eslint prefer-const: "off" */

const {ethers} = require('hardhat');
require('dotenv').config();
const mintFacet = require('../artifacts/contracts/facets/MintFacet.sol/MintFacet.json');

async function mintOnGoerli() {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];

    const MintFacet = await ethers.getContractFactory('MintFacet');

    const mintFacet = await MintFacet.attach('0xC6F7A5D7810D872FFe90407f34F50DB495Eca39B');

    await mintFacet.mint();
}
mintOnGoerli();
