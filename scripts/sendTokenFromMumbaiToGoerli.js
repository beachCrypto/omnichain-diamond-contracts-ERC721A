// /* global ethers */
// /* eslint prefer-const: "off" */

require('dotenv').config();
const {ethers} = require('hardhat');

const eRC721A = require('../artifacts/contracts/ERC721A-Contracts/ERC721AUpgradeable.sol/ERC721AUpgradeable.json');

const diamondAddressA = process.env.DIAMOND_CONTRACT_ADDRESS_MUMBAI;
// Mumbai
const chainId_A = process.env.CHAIN_A;
// Goerli
const chainId_B = process.env.CHAIN_B;

const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 500000]);
console.log('defaultAdapterParams', defaultAdapterParams);
console.log('ethers.constants.AddressZero', ethers.constants.AddressZero);
async function sendTokenFromMumbaiToGoerli() {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];
    console.log('contractOwner', contractOwner.address);
    const ERC721 = await ethers.getContractFactory('ERC721AUpgradeable');

    // Attach to diamond contract
    const eRC721A = await ERC721.attach(diamondAddressA);

    // Approve contract to transfer tokenId
    let tokenId = 100;
    // ownerOf;
    let ownerOfToken1 = await eRC721A.ownerOf(tokenId);
    console.log('ownerOfToken1', ownerOfToken1);
    // approve
    await eRC721A.approve(diamondAddressA, tokenId);

    // estimate nativeFees
    let nativeFee = (
        await eRC721A.estimateSendFee(chainId_B, contractOwner.address, tokenId, false, defaultAdapterParams)
    ).nativeFee;

    // Minimum gas must be less than value for defaultAdapterParams
    await eRC721A.setMinDstGas(chainId_B, 1, 400000);

    // swaps token to other chain
    await eRC721A.sendFrom(
        contractOwner.address,
        chainId_B,
        contractOwner.address,
        tokenId,
        contractOwner.address,
        ethers.constants.AddressZero,
        defaultAdapterParams,
        {value: nativeFee}
    );
}

sendTokenFromMumbaiToGoerli();
