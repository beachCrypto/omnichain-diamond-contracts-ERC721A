/* global ethers */
/* eslint prefer-const: "off" */

const {ethers} = require('hardhat');
require('dotenv').config();
const mintFacet = require('../artifacts/contracts/facets/MintFacet.sol/MintFacet.json');

async function setTrustedRemotesFromGoerliToMumbai() {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];

    const ERC721 = await ethers.getContractFactory('ERC721');

    const eRC721A = await ERC721.attach('0xC6F7A5D7810D872FFe90407f34F50DB495Eca39B');

    await eRC721A.setTrustedRemote(
        10109,
        ethers.utils.solidityPack(
            ['address', 'address'],
            ['0x0f8cd04c35b9ab08ea42e72e1f8636e4ac7b60c6', '0xc6f7a5d7810d872ffe90407f34f50db495eca39b']
        )
    );
}

setTrustedRemotesFromGoerliToMumbai();
