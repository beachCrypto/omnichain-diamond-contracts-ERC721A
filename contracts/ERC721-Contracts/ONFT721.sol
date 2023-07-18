// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721 using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 * */

import {IONFT721CoreUpgradeable} from '../ONFT-Contracts/IONFT721CoreUpgradeable.sol';
import '../layerZeroUpgradeable/NonblockingLzAppUpgradeable.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';

import {ERC721Internal} from './ERC721Internal.sol';
import {LayerZeroEndpointStorage} from '../layerZeroLibraries/LayerZeroEndpointStorage.sol';
import {NonblockingLzAppStorage} from '../layerZeroUpgradeable/NonblockingLzAppStorage.sol';
import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';

import {ONFTStorage} from '../ONFT-Contracts/ONFTStorage.sol';

contract ONFT721 is ERC721Internal, NonblockingLzAppUpgradeable, IONFT721CoreUpgradeable {
    using ExcessivelySafeCall for address;

    // =============================================================
    //                      LZ Send Operations
    // =============================================================

    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        bool _useZro,
        bytes memory _adapterParams
    ) public view override returns (uint nativeFee, uint zroFee) {
        return estimateSendBatchFee(_dstChainId, _toAddress, _toSingletonArray(_tokenId), _useZro, _adapterParams);
    }

    function estimateSendBatchFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        bool _useZro,
        bytes memory _adapterParams
    ) public view override returns (uint nativeFee, uint zroFee) {
        uint256 len = _tokenIds.length;
        uint256[] memory dirtBikeVINS = new uint[](len);
        for (uint i = 0; i < _tokenIds.length; i++) {
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

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), 'ONFT721: send caller is not owner nor approved');
        require(_ownerOf(_tokenId) == _from, 'ONFT721: send from incorrect owner');
        _transfer(_from, address(this), _tokenId);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable override {
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
    ) public payable override {
        _send(_from, _dstChainId, _toAddress, _tokenIds, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal {
        // allow 1 by default
        require(_tokenIds.length > 0, 'LzApp: tokenIds[] is empty');
        require(
            _tokenIds.length == 1 ||
                _tokenIds.length <= ONFTStorage.oNFTStorageLayout().dstChainIdToBatchLimit[_dstChainId],
            'ONFT721: batch size exceeds dst batch limit'
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
    ) internal {
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
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public override {
        // lzReceive must be called by the endpoint for security
        require(
            _msgSender() == address(LayerZeroEndpointStorage.layerZeroEndpointSlot().lzEndpoint),
            'LzApp: invalid endpoint caller'
        );

        bytes memory trustedRemote = NonblockingLzAppStorage.nonblockingLzAppSlot().trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            'LzApp: invalid source sending contract'
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload)
        );
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public {
        // only internal transaction
        require(_msgSender() == address(this), 'NonblockingLzApp: caller must be LzApp');
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint[] memory tokenIds, uint256[] memory dirtBikeVINs) = abi.decode(
            _payload,
            (bytes, uint[], uint256[])
        );

        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        uint nextIndex = _creditTill(_srcChainId, toAddress, 0, tokenIds);
        if (nextIndex < tokenIds.length) {
            // not enough gas to complete transfers, store to be cleared in another tx
            bytes32 hashedPayload = keccak256(_payload);
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload] = ONFTStorage.StoredCredit(
                _srcChainId,
                toAddress,
                nextIndex,
                true
            );
            emit CreditStored(hashedPayload, _payload);
        }

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenIds);
    }

    function clearCredits(bytes memory _payload) external {
        bytes32 hashedPayload = keccak256(_payload);
        require(
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].creditsRemain,
            'ONFT721: no credits stored'
        );

        (, uint[] memory tokenIds) = abi.decode(_payload, (bytes, uint[]));

        uint nextIndex = _creditTill(
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].srcChainId,
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].toAddress,
            ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].index,
            tokenIds
        );
        require(
            nextIndex > ONFTStorage.oNFTStorageLayout().storedCredits[hashedPayload].index,
            'ONFT721: not enough gas to process credit transfer'
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

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal {
        require(!_exists(_tokenId) || (_exists(_tokenId) && _ownerOf(_tokenId) == address(this)));
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
        } else {
            _transfer(address(this), _toAddress, _tokenId);
        }
    }

    // =============================================================
    //                      Non blocking receive
    // =============================================================

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
}
