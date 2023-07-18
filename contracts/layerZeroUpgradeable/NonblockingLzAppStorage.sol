// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library NonblockingLzAppStorage {
    struct NonblockingLzAppSlot {
        bool useCustomAdapterParams;
        mapping(uint16 => bytes) trustedRemoteLookup;
        mapping(uint16 => mapping(uint => uint)) minDstGasLookup;
        mapping(uint16 => uint) payloadSizeLimitLookup;
        mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) failedMessages;
        address precrime;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('omnichainDiamond.contracts.storage.NonblockingLzApp');

    function nonblockingLzAppSlot() internal pure returns (NonblockingLzAppSlot storage nblks) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            nblks.slot := slot
        }
    }
}
