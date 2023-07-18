// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library DirtBikesStorage {
    struct DirtBikesLayout {
        mapping(uint => uint256) dirtBikeVIN;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('beachCrypto.contracts.storage.DirtBikesStorage');

    function dirtBikeslayout() internal pure returns (DirtBikesLayout storage dbl) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            dbl.slot := slot
        }
    }
}
