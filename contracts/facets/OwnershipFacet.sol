// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721A using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 * */

import {IERC173} from '../interfaces/IERC173.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
