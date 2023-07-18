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

    // Approve contract to transfer tokenId
    let tokenId = 16;
    await eRC721A.approve('0xC6F7A5D7810D872FFe90407f34F50DB495Eca39B', tokenId);

    // estimate nativeFees
    // let nativeFee = (await eRC721_chainA.estimateSendFee(chainId_B, warlock.address, tokenId, false, '0x')).nativeFee;
    //let nativeFee = (await eRC721A.estimateSendFee(10109, contractOwner.address, tokenId, false, '0x')).nativeFee;

    // swaps token to other chain
    await eRC721A.sendFrom(
        contractOwner.address,
        10109,
        contractOwner.address,
        tokenId,
        contractOwner.address,
        ethers.constants.AddressZero,
        '0x',
        {value: 90000000000000}
    );
}

setTrustedRemotesFromGoerliToMumbai();
