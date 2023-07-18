/* global ethers */
/* eslint prefer-const: "off" */

const {ethers} = require('hardhat');
require('dotenv').config();
const mintFacet = require('../artifacts/contracts/facets/MintFacet.sol/MintFacet.json');

async function setTrustedRemotesFromMumbaiToGoerli() {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];

    const ERC721 = await ethers.getContractFactory('ERC721');

    const eRC721B = await ERC721.attach('0x0F8cd04c35b9aB08ea42e72E1F8636e4AC7B60C6');

    await eRC721B.setTrustedRemote(
        10121,
        ethers.utils.solidityPack(
            ['address', 'address'],
            ['0xc6f7a5d7810d872ffe90407f34f50db495eca39b', '0x0f8cd04c35b9ab08ea42e72e1f8636e4ac7b60c6']
        )
    );
}

setTrustedRemotesFromMumbaiToGoerli();
