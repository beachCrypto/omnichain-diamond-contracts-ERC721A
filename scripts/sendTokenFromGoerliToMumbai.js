// /* global ethers */
// /* eslint prefer-const: "off" */

require('dotenv').config();
const {ethers} = require('hardhat');

const oNFT721 = require('../artifacts/contracts/ERC721-Contracts/ONFT721.sol/ONFT721.json');
const eRC721 = require('../artifacts/contracts/ERC721-Contracts/ERC721.sol/ERC721.json');

const diamondAddressB = process.env.DIAMOND_CONTRACT_ADDRESS_GOERLI;
// Mumbai
const chainId_A = process.env.CHAIN_A;
// Goerli
const chainId_B = process.env.CHAIN_B;

const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 500000]);
console.log('defaultAdapterParams', defaultAdapterParams);
console.log('ethers.constants.AddressZero', ethers.constants.AddressZero);
async function sendTokenFromGoerliToMumbai() {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];
    console.log('contractOwner', contractOwner.address);
    const ONFT721 = await ethers.getContractFactory('ONFT721');
    const ERC721 = await ethers.getContractFactory('ERC721');

    // Attach to diamond contract
    const oNFT721 = await ONFT721.attach(diamondAddressB);
    const eRC721 = await ERC721.attach(diamondAddressB);

    // Approve contract to transfer tokenId
    let tokenId = 100;
    // ownerOf;
    let ownerOfToken1 = await eRC721.ownerOf(tokenId);
    console.log('ownerOfToken1', ownerOfToken1);
    // approve
    await eRC721.approve(diamondAddressB, tokenId);

    // estimate nativeFees
    let nativeFee = (
        await oNFT721.estimateSendFee(chainId_B, contractOwner.address, tokenId, false, defaultAdapterParams)
    ).nativeFee;

    // Minimum gas must be less than value for defaultAdapterParams
    await oNFT721.setMinDstGas(chainId_A, 1, 400000);

    // swaps token to other chain
    await oNFT721.sendFrom(
        contractOwner.address,
        chainId_A,
        contractOwner.address,
        tokenId,
        contractOwner.address,
        ethers.constants.AddressZero,
        defaultAdapterParams,
        {value: nativeFee}
    );
}

sendTokenFromGoerliToMumbai();
