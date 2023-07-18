/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployERC721ADiamondA} = require('../scripts/deployERC721A_a.js');
const {offsettedIndex} = require('./helpers/helpers.js');

const {assert, expect} = require('chai');

const {ethers} = require('hardhat');

let offsetted;

describe('ERC721A Functions', async () => {
    // Diamond contracts
    let diamondAddressA;
    let eRC721A;
    let owner;
    const defaultAdapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 200000]);

    // Layer Zero
    const name = 'ERC721A';
    const symbol = '721A';

    before(async function () {});

    beforeEach(async () => {
        diamondAddressA = await deployERC721ADiamondA();

        mintFacet_chainA = await ethers.getContractAt('MintFacet', diamondAddressA);

        eRC721_chainA = await ethers.getContractAt('ERC721AUpgradeable', diamondAddressA);

        const [owner, addr1] = await ethers.getSigners();

        ownerAddress = owner;
        warlock = addr1;
    });

    it('Sender can mint an NFT', async () => {
        const tokenId = 1;

        expect(await eRC721_chainA.connect(ownerAddress).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.mint(2);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainA.ownerOf(0)).to.be.equal(ownerAddress.address);
        expect(await eRC721_chainA.ownerOf(1)).to.be.equal(ownerAddress.address);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(2);

        await eRC721_chainA.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).ownerOf(tokenId)).to.equal(warlock.address);

        await eRC721_chainA.connect(warlock).approve(eRC721_chainA.address, tokenId);
    });

    it('Sender can transfer an NFT', async () => {
        const tokenId = 1;
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.mint(2);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainA.ownerOf(0)).to.be.equal(ownerAddress.address);
        expect(await eRC721_chainA.ownerOf(1)).to.be.equal(ownerAddress.address);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(2);

        await eRC721_chainA.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).ownerOf(tokenId)).to.equal(warlock.address);
    });

    it('Sender can approve an NFT', async () => {
        const tokenId = 1;
        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(0);

        await mintFacet_chainA.mint(2);

        // verify the owner of the token is on the source chain
        expect(await eRC721_chainA.ownerOf(0)).to.be.equal(ownerAddress.address);
        expect(await eRC721_chainA.ownerOf(1)).to.be.equal(ownerAddress.address);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(2);

        await eRC721_chainA.transferFrom(ownerAddress.address, warlock.address, tokenId);

        expect(await eRC721_chainA.connect(ownerAddress.address).balanceOf(ownerAddress.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).balanceOf(warlock.address)).to.equal(1);

        expect(await eRC721_chainA.connect(warlock.address).ownerOf(tokenId)).to.equal(warlock.address);

        await eRC721_chainA.connect(warlock).approve(eRC721_chainA.address, tokenId);
    });
});
