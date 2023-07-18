// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721 using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 * */

library ERC721Storage {
    struct Layout {
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to owner address
        mapping(uint256 => address) _owners;
        // Mapping owner address to token count
        mapping(address => uint256) _balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('omnichainDiamond.contracts.storage.ERC721Storage');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
