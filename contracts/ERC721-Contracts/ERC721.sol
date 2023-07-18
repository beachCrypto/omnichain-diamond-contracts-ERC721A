// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721 using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 * */

import '../layerZeroUpgradeable/NonblockingLzAppUpgradeable.sol';
import '../libraries/LibDiamond.sol';

import {ERC721Internal} from './ERC721Internal.sol';

contract ERC721 is ERC721Internal {
    using ExcessivelySafeCall for address;

    function name() public view returns (string memory) {
        return _name();
    }

    function symbol() public view returns (string memory) {
        return _symbol();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), 'ERC721: address zero is not a valid owner');
        return _balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), 'ERC721: invalid token ID');
        return owner;
    }

    function rawOwnerOf(uint256 tokenId) public view returns (address) {
        if (_exists(tokenId)) {
            return ownerOf(tokenId);
        }
        return address(0);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = _ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721: approve caller is not token owner or approved for all'
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: caller is not token owner or approved');

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: caller is not token owner or approved');
        _safeTransfer(from, to, tokenId, data);
    }
}
