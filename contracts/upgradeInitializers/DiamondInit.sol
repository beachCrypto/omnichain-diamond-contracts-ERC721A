// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Diamond interfaces
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {IDiamondLoupe} from '../interfaces/IDiamondLoupe.sol';
import {IDiamondCut} from '../interfaces/IDiamondCut.sol';

// ERC721 interfaces
import {IERC173} from '../interfaces/IERC173.sol';
import {IERC165} from '../interfaces/IERC165.sol';
import {IERC721AUpgradeable} from '../ERC721A-Contracts/IERC721AUpgradeable.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

// ERC721A Storage
import {ERC721AStorage} from '../ERC721A-Contracts/ERC721AStorage.sol';

// LayerZero interfaces
import {IONFT721CoreUpgradeable} from '../ONFT-Contracts/IONFT721CoreUpgradeable.sol';
import {ILayerZeroReceiverUpgradeable} from '../layerZeroInterfaces/ILayerZeroReceiverUpgradeable.sol';
import {ILayerZeroEndpoint} from '../layerZeroInterfaces/ILayerZeroEndpoint.sol';
import {ILayerZeroUserApplicationConfig} from '../layerZeroInterfaces/ILayerZeroUserApplicationConfig.sol';

import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';

// LayerZero Storage
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721AUpgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IONFT721CoreUpgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroReceiverUpgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroEndpoint).interfaceId] = true;
        ds.supportedInterfaces[type(ILayerZeroUserApplicationConfig).interfaceId] = true;

        // Initialize ERC721A state variables
        ERC721AStorage.Layout storage l = ERC721AStorage.layout();
        l._name = 'Dirt Bikes';
        l._symbol = 'Brap';

        // Initialize ONFT state variables

        ONFTStorage.ONFTStorageLayout storage onfts = ONFTStorage.oNFTStorageLayout();
        onfts.nextMintId = 0;
        onfts.minGasToTransferAndStore = 400000;

        // Initialize / set LayerZero endpoint
        // NFTs minted on Mumbai

        LayerZeroEndpointStorage.LayerZeroSlot storage lzep = LayerZeroEndpointStorage.layerZeroEndpointSlot();
        lzep.lzEndpoint = ILayerZeroEndpoint(0xf69186dfBa60DdB133E91E9A4B5673624293d8F8);
    }
}
