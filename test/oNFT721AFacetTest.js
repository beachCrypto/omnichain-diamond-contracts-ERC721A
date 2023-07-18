/* global ethers describe before it */
/* eslint-disable prefer-const */

const {deployERC721ADiamondA} = require('../scripts/deployERC721A_a.js');
const {deployERC721DiamondB} = require('../scripts/deployERC721_b.js');

const {assert, expect} = require('chai');
const {ethers} = require('hardhat');
const {Web3} = require('web3');
const web3 = new Web3();

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
    });
    it('sendFrom() - reverts if not owner', async function () {
        const tokenId = 1;
        await mintFacet_chainA.mint(5);

        // approve the contract to swap your token
        await eRC721A_chainA.approve(eRC721A_chainA.address, tokenId);

        // estimate nativeFees
        let nativeFee = (
            await oNFT721_chainB.estimateSendFee(chainId_B, ownerAddress.address, tokenId, false, defaultAdapterParams)
        ).nativeFee;

        // swaps token to other chain
        await eRC721A_chainA.sendFrom(
            ownerAddress.address,
            chainId_B,
            ownerAddress.address,
            tokenId,
            ownerAddress.address,
            ethers.constants.AddressZero,
            defaultAdapterParams,
            {value: nativeFee}
        );

        // token received on the dst chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // reverts because other address does not own it
        await expect(
            oNFT721_chainB
                .connect(warlock)
                .sendFrom(
                    warlock.address,
                    chainId_A,
                    warlock.address,
                    tokenId,
                    warlock.address,
                    ethers.constants.AddressZero,
                    defaultAdapterParams,
                    {value: nativeFee}
                )
        ).to.be.revertedWith('ONFT721: send caller is not owner nor approved');
    });

    it('sendFrom() - on behalf of other user', async function () {
        const tokenId = 0;
        await mintFacet_chainA.mint(1);

        // approve the contract to swap your token
        await eRC721A_chainA.approve(eRC721A_chainA.address, tokenId);

        // estimate nativeFees
        let nativeFee = (
            await oNFT721_chainB.estimateSendFee(chainId_B, ownerAddress.address, tokenId, false, defaultAdapterParams)
        ).nativeFee;

        // swaps token to other chain
        await eRC721A_chainA.sendFrom(
            ownerAddress.address,
            chainId_B,
            ownerAddress.address,
            tokenId,
            ownerAddress.address,
            ethers.constants.AddressZero,
            defaultAdapterParams,
            {value: nativeFee}
        );

        // token received on the dst chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // approve the other user to send the token
        await eRC721_chainB.approve(warlock.address, tokenId);

        // sends across
        await oNFT721_chainB
            .connect(warlock)
            .sendFrom(
                ownerAddress.address,
                chainId_A,
                warlock.address,
                tokenId,
                warlock.address,
                ethers.constants.AddressZero,
                defaultAdapterParams,
                {
                    value: nativeFee,
                }
            );

        // token received on the dst chain
        expect(await eRC721A_chainA.ownerOf(tokenId)).to.be.equal(warlock.address);
    });

    it('sendFrom() - reverts if contract is approved, but not the sending user', async function () {
        const tokenId = 0;
        await mintFacet_chainA.mint(1);

        // approve the contract to swap your token
        await eRC721A_chainA.approve(eRC721A_chainA.address, tokenId);

        // estimate nativeFees
        let nativeFee = (
            await oNFT721_chainB.estimateSendFee(chainId_B, ownerAddress.address, tokenId, false, defaultAdapterParams)
        ).nativeFee;

        // swaps token to other chain
        await eRC721A_chainA.sendFrom(
            ownerAddress.address,
            chainId_B,
            ownerAddress.address,
            tokenId,
            ownerAddress.address,
            ethers.constants.AddressZero,
            defaultAdapterParams,
            {value: nativeFee}
        );

        // token received on the dst chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // approve the contract to swap your token
        await eRC721_chainB.approve(eRC721_chainB.address, tokenId);

        // reverts because contract is approved, not the user
        await expect(
            oNFT721_chainB
                .connect(warlock)
                .sendFrom(
                    ownerAddress.address,
                    chainId_A,
                    warlock.address,
                    tokenId,
                    warlock.address,
                    ethers.constants.AddressZero,
                    defaultAdapterParams,
                    {value: nativeFee}
                )
        ).to.be.revertedWith('ONFT721: send caller is not owner nor approved');
    });

    it('sendFrom() - reverts if not approved', async function () {
        const tokenId = 0;
        await mintFacet_chainA.mint(1);

        // approve the contract to swap your token
        await eRC721A_chainA.approve(eRC721A_chainA.address, tokenId);

        // estimate nativeFees
        let nativeFee = (
            await oNFT721_chainB.estimateSendFee(chainId_B, ownerAddress.address, tokenId, false, defaultAdapterParams)
        ).nativeFee;

        // swaps token to other chain
        await eRC721A_chainA.sendFrom(
            ownerAddress.address,
            chainId_B,
            ownerAddress.address,
            tokenId,
            ownerAddress.address,
            ethers.constants.AddressZero,
            defaultAdapterParams,
            {value: nativeFee}
        );

        // token received on the dst chain
        expect(await eRC721_chainB.ownerOf(tokenId)).to.be.equal(ownerAddress.address);

        // reverts because user is not approved
        await expect(
            oNFT721_chainB
                .connect(warlock)
                .sendFrom(
                    ownerAddress.address,
                    chainId_A,
                    warlock.address,
                    tokenId,
                    warlock.address,
                    ethers.constants.AddressZero,
                    defaultAdapterParams,
                    {value: nativeFee}
                )
        ).to.be.revertedWith('ONFT721: send caller is not owner nor approved');
    });

    it('sendFrom() - reverts if sender does not own token', async function () {
        const tokenIdA = 0;
        await mintFacet_chainA.mint(1);

        // approve owner.address to transfer, but not the other
        await eRC721A_chainA.setApprovalForAll(eRC721A_chainA.address, true);

        // estimate nativeFees
        let nativeFee = (
            await eRC721A_chainA.estimateSendFee(chainId_B, ownerAddress.address, tokenIdA, false, defaultAdapterParams)
        ).nativeFee;

        await expect(
            eRC721A_chainA
                .connect(warlock)
                .sendFrom(
                    warlock.address,
                    chainId_B,
                    warlock.address,
                    tokenIdA,
                    warlock.address,
                    ethers.constants.AddressZero,
                    defaultAdapterParams,
                    {value: nativeFee}
                )
        ).to.be.revertedWith('TransferFromIncorrectOwner()');

        await expect(
            eRC721A_chainA
                .connect(warlock)
                .sendFrom(
                    warlock.address,
                    chainId_B,
                    ownerAddress.address,
                    tokenIdA,
                    ownerAddress.address,
                    ethers.constants.AddressZero,
                    defaultAdapterParams,
                    {value: nativeFee}
                )
        ).to.be.revertedWith('TransferFromIncorrectOwner()');
    });

    // TODO: Create mock storage for NFT hash stored and transfered
    // These tests use a mock payload. The NFT hash is not part of this mock and breaks the tests. The NFT hash is stored and cannot be accessed here as is
    // it('sendBatchFrom()', async function () {
    //     await eRC721A_chainA.setMinGasToTransferAndStore(400000);
    //     await eRC721_chainB.setMinGasToTransferAndStore(400000);
    //     await eRC721A_chainA.setDstChainIdToBatchLimit(chainId_B, batchSizeLimit);
    //     await eRC721_chainB.setDstChainIdToBatchLimit(chainId_A, batchSizeLimit);
    //     const tokenIds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    //     // mint to owner
    //     await mintFacet_chainA.connect(warlock).mint(10);

    //     // approve owner.address to transfer
    //     await eRC721A_chainA.connect(warlock).setApprovalForAll(eRC721A_chainA.address, true);

    //     // expected event params
    //     const payload = ethers.utils.defaultAbiCoder.encode(['bytes', 'uint[]'], [warlock.address, tokenIds]);
    //     const hashedPayload = web3.utils.keccak256(payload);

    //     let adapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 200000]);

    //     // estimate nativeFees
    //     let nativeFee = (
    //         await eRC721A_chainA.estimateSendBatchFee(chainId_B, warlock.address, tokenIds, false, defaultAdapterParams)
    //     ).nativeFee;

    //     // initiate batch transfer
    //     await expect(
    //         eRC721A_chainA.connect(warlock).sendBatchFrom(
    //             warlock.address,
    //             chainId_B,
    //             warlock.address,
    //             tokenIds,
    //             warlock.address,
    //             ethers.constants.AddressZero,
    //             adapterParams, // TODO might need to change this
    //             {value: nativeFee}
    //         )
    //     )
    //         .to.emit(eRC721_chainB, 'CreditStored')
    //         .withArgs(hashedPayload, payload);

    //     // only partial amount of tokens has been sent, the rest have been stored as a credit
    //     let creditedIdsA = [];
    //     for (let tokenId of tokenIds) {
    //         let owner = await eRC721_chainB.rawOwnerOf(tokenId);
    //         if (owner == ethers.constants.AddressZero) {
    //             creditedIdsA.push(tokenId);
    //         } else {
    //             expect(owner).to.be.equal(warlock.address);
    //         }
    //     }

    //     // clear the rest of the credits
    //     await expect(eRC721_chainB.clearCredits(payload))
    //         .to.emit(eRC721_chainB, 'CreditCleared')
    //         .withArgs(hashedPayload);

    //     let creditedIdsB = [];
    //     for (let tokenId of creditedIdsA) {
    //         let owner = await eRC721_chainB.rawOwnerOf(tokenId);
    //         if (owner == ethers.constants.AddressZero) {
    //             creditedIdsB.push(tokenId);
    //         } else {
    //             expect(owner).to.be.equal(warlock.address);
    //         }
    //     }

    //     // all ids should have cleared
    //     expect(creditedIdsB.length).to.be.equal(0);

    //     // should revert because payload is no longer valid
    //     await expect(eRC721_chainB.clearCredits(payload)).to.be.revertedWith('no credits stored');
    // });

    // it('sendBatchFrom() - large batch', async function () {
    //     await eRC721A_chainA.setMinGasToTransferAndStore(400000);
    //     await eRC721_chainB.setMinGasToTransferAndStore(400000);
    //     await eRC721A_chainA.setDstChainIdToBatchLimit(chainId_B, batchSizeLimit);
    //     await eRC721_chainB.setDstChainIdToBatchLimit(chainId_A, batchSizeLimit);

    //     const tokenIds = [];

    //     for (let i = 0; i < 150; i++) {
    //         tokenIds.push(i);
    //     }

    //     // mint to owner
    //     for (let tokenId of tokenIds) {
    //         await mintFacet_chainA.connect(warlock).mint(1);
    //     }

    //     // approve owner.address to transfer
    //     await eRC721A_chainA.connect(warlock).setApprovalForAll(eRC721A_chainA.address, true);

    //     // expected event params
    //     const payload = ethers.utils.defaultAbiCoder.encode(['bytes', 'uint[]'], [warlock.address, tokenIds]);
    //     const hashedPayload = web3.utils.keccak256(payload);

    //     // Increase amount of gas to sent for this to pass tests
    //     // let adapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 400000]);
    //     let adapterParams = ethers.utils.solidityPack(['uint16', 'uint256'], [1, 1000000]);

    //     // estimate nativeFees
    //     let nativeFee = (
    //         await eRC721A_chainA.estimateSendBatchFee(chainId_B, warlock.address, tokenIds, false, adapterParams)
    //     ).nativeFee;

    //     // initiate batch transfer
    //     await expect(
    //         eRC721A_chainA.connect(warlock).sendBatchFrom(
    //             warlock.address,
    //             chainId_B,
    //             warlock.address,
    //             tokenIds,
    //             warlock.address,
    //             ethers.constants.AddressZero,
    //             adapterParams, // TODO might need to change this
    //             {value: nativeFee}
    //         )
    //     )
    //         .to.emit(eRC721_chainB, 'CreditStored')
    //         .withArgs(hashedPayload, payload);

    //     // only partial amount of tokens has been sent, the rest have been stored as a credit
    //     let creditedIdsA = [];
    //     for (let tokenId of tokenIds) {
    //         let owner = await eRC721_chainB.rawOwnerOf(tokenId);
    //         if (owner == ethers.constants.AddressZero) {
    //             creditedIdsA.push(tokenId);
    //         } else {
    //             expect(owner).to.be.equal(warlock.address);
    //         }
    //     }

    //     // console.log("Number of tokens credited: ", creditedIdsA.length)

    //     // clear the rest of the credits
    //     let tx = await (await eRC721_chainB.clearCredits(payload)).wait();

    //     // console.log("Total gasUsed: ", tx.gasUsed.toString())

    //     let creditedIdsB = [];
    //     for (let tokenId of creditedIdsA) {
    //         let owner = await eRC721_chainB.rawOwnerOf(tokenId);
    //         if (owner == ethers.constants.AddressZero) {
    //             creditedIdsB.push(tokenId);
    //         } else {
    //             expect(owner).to.be.equal(warlock.address);
    //         }
    //     }

    //     // console.log("Number of tokens credited: ", creditedIdsB.length)

    //     // all ids should have cleared
    //     expect(creditedIdsB.length).to.be.equal(0);

    //     // should revert because payload is no longer valid
    //     await expect(eRC721_chainB.clearCredits(payload)).to.be.revertedWith('no credits stored');
    // });
});
