// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library ONFTStorage {
    struct StoredCredit {
        uint16 srcChainId;
        address toAddress;
        uint256 index; // which index of the tokenIds remain
        bool creditsRemain;
    }

    struct ONFTStorageLayout {
        uint nextMintId;
        uint maxMintId;
        uint256 minGasToTransferAndStore; // min amount of gas required to transfer, and also store the payload
        mapping(uint16 => uint256) dstChainIdToBatchLimit;
        mapping(uint16 => uint256) dstChainIdToTransferGas; // per transfer amount of gas required to mint/transfer on the dst
        mapping(bytes32 => ONFTStorage.StoredCredit) storedCredits;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('omnichainDiamond.contracts.storage.ONFTStorageStorage');

    function oNFTStorageLayout() internal pure returns (ONFTStorageLayout storage onfts) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            onfts.slot := slot
        }
    }
}
