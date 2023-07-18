// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721A using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 * */

import '../layerZeroInterfaces/ILayerZeroEndpoint.sol';

library LayerZeroEndpointStorage {
    struct LayerZeroSlot {
        ILayerZeroEndpoint lzEndpoint;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('omnichainDiamond.contracts.storage.lZEndpoint');

    function layerZeroEndpointSlot() internal pure returns (LayerZeroSlot storage lzep) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            lzep.slot := slot
        }
    }
}
