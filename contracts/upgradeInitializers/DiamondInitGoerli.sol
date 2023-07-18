// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

// Diamond interfaces
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {IDiamondLoupe} from '../interfaces/IDiamondLoupe.sol';
import {IDiamondCut} from '../interfaces/IDiamondCut.sol';

// ERC721 interfaces
import {IERC173} from '../interfaces/IERC173.sol';
import {IERC165} from '../interfaces/IERC165.sol';
import {IERC721} from '../ERC721-Contracts/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

// ERC721 Storage
import {ERC721Storage} from '../../contracts/ERC721-Contracts/ERC721Storage.sol';

// LayerZero interfaces
import {IONFT721CoreUpgradeable} from '../ONFT-Contracts/IONFT721CoreUpgradeable.sol';
import {ILayerZeroReceiverUpgradeable} from '../layerZeroInterfaces/ILayerZeroReceiverUpgradeable.sol';
import {ILayerZeroEndpoint} from '../layerZeroInterfaces/ILayerZeroEndpoint.sol';
import {ILayerZeroUserApplicationConfig} from '../layerZeroInterfaces/ILayerZeroUserApplicationConfig.sol';

import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';

// LayerZero Storage
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';

contract DiamondInitGoerli {
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IONFT721CoreUpgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroReceiverUpgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroEndpoint).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroUserApplicationConfig).interfaceId] = true;

        // Initialize ERC721A state variables
        ERC721Storage.Layout storage l = ERC721Storage.layout();
        l._name = 'Dirt Bikes';
        l._symbol = 'Brap';

        // Initialize ONFT state variables

        ONFTStorage.ONFTStorageLayout storage onfts = ONFTStorage.oNFTStorageLayout();
        onfts.minGasToTransferAndStore = 100000;

        // Initialize / set LayerZero endpoint
        // Goerli

        LayerZeroEndpointStorage.LayerZeroSlot storage lzep = LayerZeroEndpointStorage.layerZeroEndpointSlot();
        lzep.lzEndpoint = ILayerZeroEndpoint(0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23);
    }
}
