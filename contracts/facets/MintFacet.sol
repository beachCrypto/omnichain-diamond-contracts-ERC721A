// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721A using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 * */

import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ERC721AUpgradeableInternal} from '../ERC721A-Contracts/ERC721AUpgradeableInternal.sol';
import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';

contract MintFacet is ERC721AUpgradeableInternal {
    event DirtBikeCreated(uint indexed tokenId);

    uint public nextMintId;
    uint public maxMintId;

    function getPseudoRandomHash(uint256 tokenId) public view returns (uint256) {
        // generate psuedo-randomHash
        uint256 randomHash = (uint256(keccak256(abi.encodePacked((block.timestamp / 10), tokenId + 1))));

        return randomHash;
    }

    function mint(uint _amount) external payable {
        nextMintId = ONFTStorage.oNFTStorageLayout().nextMintId;

        for (uint i = 0; i < _amount; i++) {
            uint256 tokenId = nextMintId + i;
            uint256 dirtBikeHash = getPseudoRandomHash(tokenId);
            DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[tokenId] = dirtBikeHash;

            emit DirtBikeCreated(tokenId);
        }

        ONFTStorage.oNFTStorageLayout().nextMintId = nextMintId + _amount;

        _safeMint(msg.sender, _amount, '');
    }
}
