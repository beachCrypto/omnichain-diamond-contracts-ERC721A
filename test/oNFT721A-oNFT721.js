/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployERC721ADiamondA} = require('../scripts/deployERC721A_a.js');
const {deployERC721DiamondB} = require('../scripts/deployERC721_b.js');
const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');
const {ethers} = require('hardhat');
const {Web3} = require('web3');
const web3 = new Web3();

let offsetted;

describe('sendFrom()', async () => {
    // Diamond contracts
    let diamondAddressA;
    let diamondAddressB;
    let eRC721A_chainA;
    let eRC721_chainB;
    let oNFT721_chainB;
    let mintFacet_chainA;
    let NonblockingLzAppUpgradeableA;
    let NonblockingLzAppUpgradeableB;
    let owner;
    const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 250000]);
    const batchSizeLimit = 300;

    // Layer Zero
    const chainId_A = 1;
    const chainId_B = 2;
    const name = 'OmnichainNonFungibleToken';
    const symbol = 'ONFT';

    before(async function () {
        LZEndpointMockA = await ethers.getContractFactory('LZEndpointMockA');
        LZEndpointMockB = await ethers.getContractFactory('LZEndpointMockB');
    });

    beforeEach(async () => {
        lzEndpointMockA = await LZEndpointMockA.deploy(chainId_A);
        lzEndpointMockB = await LZEndpointMockB.deploy(chainId_B);

        // generate a proxy to allow it to go ONFT
        diamondAddressA = await deployERC721ADiamondA();
        diamondAddressB = await deployERC721DiamondB();

        eRC721A_chainA = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressA);
        eRC721_chainB = await ethers.getContractAt('ERC721', diamondAddressB);
        oNFT721_chainB = await ethers.getContractAt('ONFT721', diamondAddressB);

        mintFacet_chainA = await ethers.getContractAt('MintFacet', diamondAddressA);

        renderFacet_chainB = await ethers.getContractAt('RenderFacet', diamondAddressB);

        NonblockingLzAppUpgradeableA = await ethers.getContractAt('NonblockingLzAppUpgradeable', diamondAddressA);
        NonblockingLzAppUpgradeableB = await ethers.getContractAt('NonblockingLzAppUpgradeable', diamondAddressB);

        // wire the lz endpoints to guide msgs back and forth
        lzEndpointMockA.setDestLzEndpoint(diamondAddressB.address, lzEndpointMockB.address);
        lzEndpointMockB.setDestLzEndpoint(diamondAddressA.address, lzEndpointMockA.address);

        // set each contracts source address so it can send to each other
        await NonblockingLzAppUpgradeableA.setTrustedRemote(
            chainId_B,
            ethers.utils.solidityPack(['address', 'address'], [diamondAddressB, diamondAddressA])
        );

        await NonblockingLzAppUpgradeableB.setTrustedRemote(
            chainId_A,
            ethers.utils.solidityPack(['address', 'address'], [diamondAddressA, diamondAddressB])
        );

        await eRC721A_chainA.setMinDstGas(chainId_B, 1, 150000);
        await oNFT721_chainB.setMinDstGas(chainId_A, 1, 150000);

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;
    });

    it('sendFrom() - your own tokens', async function () {
        let tokenId = 1;
        await mintFacet_chainA.mint(2);

        // verify the owner of the token is on the source chain
        expect(await eRC721A_chainA.ownerOf(0)).to.be.equal(ownerAddress.address);
        expect(await eRC721A_chainA.ownerOf(1)).to.be.equal(ownerAddress.address);

        // token doesn't exist on other chain
        await expect(eRC721_chainB.ownerOf(tokenId)).to.be.revertedWith('ERC721: invalid token ID');

        // can transfer token on srcChain as regular erC721
        await eRC721A_chainA.transferFrom(ownerAddress.address, warlock.address, tokenId);
        expect(await eRC721A_chainA.ownerOf(tokenId)).to.be.equal(warlock.address);

        // approve the contract to swap your token
        await eRC721A_chainA.connect(warlock).approve(eRC721A_chainA.address, tokenId);

        // estimate nativeFees
        let nativeFee = (
            await eRC721A_chainA.estimateSendFee(chainId_B, ownerAddress.address, tokenId, false, defaultAdapterParams)
        ).nativeFee;

        // swaps token to other chain
        await eRC721A_chainA
            .connect(warlock)
            .sendFrom(
                warlock.address,
                chainId_B,
                warlock.address,
                tokenId,
                warlock.address,
                ethers.constants.AddressZero,
                defaultAdapterParams,
                {value: nativeFee}
            );

        // token is burnt
        expect(await eRC721A_chainA.ownerOf(0)).to.be.equal(ownerAddress.address);
        expect(await eRC721A_chainA.ownerOf(tokenId)).to.be.equal(eRC721A_chainA.address);

        // token received on the dst chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(warlock.address);

        // can send to other onft contract eg. not the original nft contract chain
        await oNFT721_chainB
            .connect(warlock)
            .sendFrom(
                warlock.address,
                chainId_A,
                ownerAddress.address,
                tokenId,
                warlock.address,
                ethers.constants.AddressZero,
                defaultAdapterParams,
                {
                    value: nativeFee,
                }
            );
        console.log('warlock.address', warlock.address);
        console.log('ownerAddress.address', ownerAddress.address);

        // token is burned on the sending chain
        expect(await eRC721A_chainA.ownerOf(tokenId)).to.be.equal(ownerAddress.address);
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(eRC721_chainB.address);
        console.log('Token URI ------>', await renderFacet_chainB.tokenURI(tokenId));
    });
});
