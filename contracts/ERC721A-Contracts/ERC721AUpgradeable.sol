// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721 using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 * ERC721A Contracts adapted from ERC721A-Upgradeable Contracts v4.2.3 by Chiru Labs
 *
 * */

import {ERC721AUpgradeableInternal, ERC721AStorage} from './ERC721AUpgradeableInternal.sol';
import {NonblockingLzAppStorage} from '../layerZeroUpgradeable/NonblockingLzAppStorage.sol';
import {NonblockingLzAppUpgradeable} from '../layerZeroUpgradeable/NonblockingLzAppUpgradeable.sol';
import {IONFT721CoreUpgradeable} from '../ONFT-Contracts/IONFT721CoreUpgradeable.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';
import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is ERC721AUpgradeableInternal, NonblockingLzAppUpgradeable, IONFT721CoreUpgradeable {
    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - ERC721AStorage.layout()._burnCounter - _startTokenId();
        }
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
        return ERC721AStorage.layout()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual returns (string memory) {
        return ERC721AStorage.layout()._name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual returns (string memory) {
        return ERC721AStorage.layout()._symbol;
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

        return ERC721AStorage.layout()._tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return ERC721AStorage.layout()._operatorApprovals[owner][operator];
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
        from = address(uint160(uint256(uint160(from)) & _BITMASK_ADDRESS));

        if (address(uint160(prevOwnershipPacked)) != from) _revert(TransferFromIncorrectOwner.selector);

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --ERC721AStorage.layout()._packedAddressData[from]; // Updates: `balance -= 1`.
            ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;
        assembly {
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                from, // `from`.
                toMasked, // `to`.
                tokenId // `tokenId`.
            )
        }
        if (toMasked == 0) _revert(TransferToZeroAddress.selector);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
    }

    // =============================================================
    //                      LZ Send Operations
    // =============================================================

    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual override returns (uint nativeFee, uint zroFee) {
        return estimateSendBatchFee(_dstChainId, _toAddress, _toSingletonArray(_tokenId), _useZro, _adapterParams);
    }

    function estimateSendBatchFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual override returns (uint nativeFee, uint zroFee) {
        uint256 len = _tokenIds.length;
        uint256[] memory dirtBikeVINS = new uint[](len);
        for (uint i = 0; i < _tokenIds.length; i++) {
            // for each token id add dirtbike vin matching that token id to dirtBikeVINS
            uint256 _dirtbikeVINHash = DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[_tokenIds[i]];
            dirtBikeVINS[i] = _dirtbikeVINHash;
        }

        bytes memory payload = abi.encode(_toAddress, _tokenIds, dirtBikeVINS);
        return
            LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                _adapterParams
            );
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external {
        LibDiamond.enforceIsContractOwner();

        NonblockingLzAppStorage.nonblockingLzAppSlot().useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    // ensures enough gas in adapter params to handle batch transfer gas amounts on the dst
    function setDstChainIdToTransferGas(uint16 _dstChainId, uint256 _dstChainIdToTransferGas) external {
        LibDiamond.enforceIsContractOwner();

        require(_dstChainIdToTransferGas > 0, 'dstChainIdToTransferGas must be > 0');
        ONFTStorage.oNFTStorageLayout().dstChainIdToTransferGas[_dstChainId] = _dstChainIdToTransferGas;
        emit SetDstChainIdToTransferGas(_dstChainId, _dstChainIdToTransferGas);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal {
        safeTransferFrom(_from, address(this), _tokenId);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual override {
        _send(
            _from,
            _dstChainId,
            _toAddress,
            _toSingletonArray(_tokenId),
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function sendBatchFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _tokenIds, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, 'LzApp: invalid adapterParams');
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        // allow 1 by default
        require(_tokenIds.length > 0, 'tokenIds[] is empty');
        require(
            _tokenIds.length == 1 ||
                _tokenIds.length <= ONFTStorage.oNFTStorageLayout().dstChainIdToBatchLimit[_dstChainId],
            'batch size exceeds dst batch limit'
        );

        uint256 len = _tokenIds.length;
        uint256[] memory dirtBikeVINS = new uint[](len);

        for (uint i = 0; i < _tokenIds.length; i++) {
            // for each token id add dirtbike vin matching that token id to dirtBikeVINS
            uint256 _dirtbikeVINHash = DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[_tokenIds[i]];
            dirtBikeVINS[i] = _dirtbikeVINHash;
            _debitFrom(_from, _dstChainId, _toAddress, _tokenIds[i]);
        }

        bytes memory payload = abi.encode(_toAddress, _tokenIds, dirtBikeVINS);

        _checkGasLimit(
            _dstChainId,
            FUNCTION_TYPE_SEND,
            _adapterParams,
            ONFTStorage.oNFTStorageLayout().dstChainIdToTransferGas[_dstChainId] * _tokenIds.length
        );
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit SendToChain(_dstChainId, _from, _toAddress, _tokenIds);
    }

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, 'LzApp: destination chain is not a trusted source');
        _checkPayloadSize(_dstChainId, _payload.length);

        LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint.send{value: _nativeFee}(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    // =============================================================
    //                     LZ Receive Operations
    // =============================================================

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security

        require(
            msg.sender == address(LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint),
            'LzApp: invalid endpoint caller'
        );

        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_srcChainId];

        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length && keccak256(_srcAddress) == keccak256(trustedRemote),
            'LzApp: invalid source sending contract'
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual {
        // try-catch all errors/exceptions
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(
                _payload
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public {
        // only internal transaction
        require(msg.sender == address(this), 'NonblockingLzApp: caller must be LzApp');
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal virtual {
        (bytes memory toAddressBytes, uint[] memory tokenIds) = abi.decode(_payload, (bytes, uint[]));

        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        uint nextIndex = _creditTill(_srcChainId, toAddress, 0, tokenIds);

        if (nextIndex < tokenIds.length) {
            // not enough gas to complete transfers, store to be cleared in another tx
            bytes32 hashedPayload = keccak256(_payload);
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload] = ONFTStorage.StoredCredit(
                ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].srcChainId,
                ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].toAddress,
                nextIndex,
                true
            );
            emit CreditStored(hashedPayload, _payload);
        }

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenIds);
    }

    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public payable {
        // assert there is message to retry
        bytes32 payloadHash = NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][
            _nonce
        ];
        require(payloadHash != bytes32(0), 'NonblockingLzApp: no stored message');
        require(keccak256(_payload) == payloadHash, 'NonblockingLzApp: invalid payload');
        // clear the stored message
        NonblockingLzAppStorage.nonblockingLzAppSlot().failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal {
        require(_exists(_tokenId) && _ownerOf(_tokenId) == address(this));
        safeTransferFrom(address(this), _toAddress, _tokenId);
    }

    function onERC721Received(address, address, uint, bytes memory) public pure returns (bytes4) {
        return ERC721A__IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // Public function for anyone to clear and deliver the remaining batch sent tokenIds
    function clearCredits(bytes memory _payload) external virtual {
        bytes32 hashedPayload = keccak256(_payload);
        require(ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].creditsRemain, 'no credits stored');

        (, uint[] memory tokenIds) = abi.decode(_payload, (bytes, uint[]));

        uint nextIndex = _creditTill(
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].srcChainId,
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].toAddress,
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].index,
            tokenIds
        );
        require(
            nextIndex > ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].index,
            'not enough gas to process credit transfer'
        );

        if (nextIndex == tokenIds.length) {
            // cleared the credits, delete the element
            delete ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload];
            emit CreditCleared(hashedPayload);
        } else {
            // store the next index to mint
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload] = ONFTStorage.StoredCredit(
                ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].srcChainId,
                ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].toAddress,
                nextIndex,
                true
            );
        }
    }

    // When a srcChain has the ability to transfer more chainIds in a single tx than the dst can do.
    // Needs the ability to iterate and stop if the minGasToTransferAndStore is not met
    function _creditTill(
        uint16 _srcChainId,
        address _toAddress,
        uint _startIndex,
        uint[] memory _tokenIds
    ) internal returns (uint256) {
        uint i = _startIndex;
        while (i < _tokenIds.length) {
            // if not enough gas to process, store this index for next loop
            if (gasleft() < ONFTStorage.oNFTStorageLayout().minGasToTransferAndStore) break;

            _creditTo(_srcChainId, _toAddress, _tokenIds[i]);

            i++;
        }

        // indicates the next index to send of tokenIds,
        // if i == tokenIds.length, we are finished
        return i;
    }
}
