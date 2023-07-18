// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @author beachcrypto.eth
 * @title Dirt Bikes Omnichain Diamond NFTs
 *
 * ONFT721A using EIP 2535: Diamonds, Multi-Facet Proxy
 *
 * */

import '@openzeppelin/contracts/utils/Base64.sol';
import '../utils/Strings.sol';

import {DirtBikesStorage} from '../libraries/LibDirtBikesStorage.sol';
import {ERC721AUpgradeableInternal} from '../ERC721A-Contracts/ERC721AUpgradeableInternal.sol';

contract RenderFacet is ERC721AUpgradeableInternal {
    using Strings for uint256;

    struct DirtBike {
        string background;
        string engine;
        string forks;
        string frontFender;
        string gasTank;
        string handlebars;
        string swingArm;
        string rearWheel;
        string rearFender;
        string frontWheel;
    }

     // Return a random background color
    function backgroundColors(uint index) internal pure returns (string memory) {
        string[10] memory bgColors = ['#66ccf3', '#85A185', '#b08f26', '#f06eaa', '#d3d6d8', '#a27ca2', '#aaa9ad', '#247881', '#00FFC6', '#9D5353'];
        return bgColors[index];
    }

    // Return a random part color
    function dirtBikePartsColors(uint index) internal pure returns (string memory) {
        string[10] memory bColors = ['#2C3333', '#00abec', '#3c643c', '#EA5C2B', '#7b457b', '#F6F1F1', '#d33a00', '#78B7BB', '#808B97', '#025464'];
        return bColors[index];
    }

    function forkColors(uint index) internal pure returns (string memory) {
        string[4] memory fColors = ['#2C3333','#E57C23', '#8c8c8c','#BE5A83'];
        return fColors[index];
    }

    function swingArm(uint index) internal pure returns (string memory) {
        string[4] memory saColors = ['#2C3333', '#8c8c8c', '#E57C23','#BE5A83'];
        return saColors[index];
    }

    function wheelColors(uint index) internal pure returns (string memory) {
        string[2] memory wColors = ['#4D4D4D', '#6f4e37'];
        return wColors[index];
    }

     // Create an instance of a DirtBike
    function createDirtBikeStruct(uint256[] memory vin) internal pure returns (DirtBike memory) {
      return
          DirtBike({
              background: backgroundColors(vin[0] % 10),
              engine: dirtBikePartsColors(vin[1]), // Choose random color from array
              forks: forkColors(vin[2] % 4),
              frontFender: dirtBikePartsColors(vin[3]),
              frontWheel: wheelColors(vin[4] % 2),
              gasTank: dirtBikePartsColors(vin[5]),
              handlebars: dirtBikePartsColors(vin[6]),
              rearWheel: wheelColors(vin[7] % 2),
              rearFender: dirtBikePartsColors(vin[8]),
              swingArm: swingArm(vin[9] % 4)
          });
    }

     function generateMetadata(DirtBike memory dirtbike)public pure returns (string memory) {
      return
        (string(abi.encodePacked(
          '"attributes": [',
                            '{"trait_type": "Background", "value": "',dirtbike.background,'"},',
                            '{"trait_type": "Engine", "value": "',dirtbike.engine,'"},',
                            '{"trait_type": "Front fender", "value": "',dirtbike.frontFender,'"},',
                            '{"trait_type": "Front wheel", "value": "',dirtbike.frontWheel,'"},',
                            '{"trait_type": "Gas Tank", "value": "',dirtbike.gasTank,'"},',
                            '{"trait_type": "Handlebars", "value": "',dirtbike.handlebars,'"},',
                            '{"trait_type": "Rear fender", "value": "',dirtbike.rearFender,'"},',
                            '{"trait_type": "Rear wheel", "value": "',dirtbike.rearWheel,'"},',
                            '{"trait_type": "Swingarm", "value": "',dirtbike.swingArm,'"}',
                        '],'

        )));
    }

    function background(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            (string(
                abi.encodePacked(
                    '<rect width="1600" height="1600" fill="',
                    dirtbike.background,
                    '" />'
                )
            ));
    }

    function rearWheelSvg(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="100" y="1000" width="100" height="200" fill="',
                    dirtbike.rearWheel,
                    '" />',
                    '<rect x="200" y="1200" width="200" height="100" fill="',
                    dirtbike.rearWheel,
                    '" />',
                    '<rect x="200" y="900" width="200" height="100" fill="',
                    dirtbike.rearWheel,
                    '" />',
                    '<rect x="400" y="1000" width="100" height="200" fill="',
                    dirtbike.rearWheel,
                    '" />'
                )
            );
    }

      function frontWheelSvg(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="1000" y="1000" width="100" height="200" fill="',
                    dirtbike.frontWheel,
                    '" />',

                    '<rect x="1100" y="1200" width="200" height="100" fill="',
                    dirtbike.frontWheel,
                    '" />',

                    '<rect x="1100" y="900" width="200" height="100" fill="',
                    dirtbike.frontWheel,
                    '" />',

                    '<rect x="1300" y="1000" width="100" height="200" fill="',
                    dirtbike.frontWheel,
                    '" />'
                )
            );
    }

    function driveTrainSvg(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(

                    // <!-- swing arm -->
                    '<rect x="300" y="1000" width="400" height="100" fill="',
                    dirtbike.swingArm,
                    '" />'

                    '<rect x="500" y="900" width="100" height="200" fill="',
                    dirtbike.swingArm,
                    '" />'

                    // <!-- engine -->
                    '<rect x="500" y="800" width="400" height="100" fill="',
                    dirtbike.engine,
                    '" />'
                    '<rect x="600" y="900" width="300" height="100" fill="',
                    dirtbike.engine,
                    '" />'
                    '<rect x="600" y="800" width="100" height="200" fill="',
                    dirtbike.engine,
                    '" />'
                    '<rect x="700" y="800" width="100" height="200" fill="',
                    dirtbike.engine,
                    '" />'
                    '<rect x="800" y="800" width="100" height="200" fill="',
                    dirtbike.engine,
                    '" />'
                )
            );
    }

    function body(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(

                    //  <!-- rear fender -->
                    '<rect x="200" y="600" width="300" height="100" fill="',
                    dirtbike.rearFender,
                    '" />'
                    '<rect x="400" y="700" width="200" height="100" fill="',
                    dirtbike.rearFender,
                    '" />'
                    '<rect x="400" y="600" width="100" height="200" fill="',
                    dirtbike.rearFender,
                    '" />'
                    // <!-- front fender -->
                    '<rect x="900" y="700" width="300" height="100" fill="',
                    dirtbike.frontFender,
                    '" />'
                    // <!-- gas tank -->
                    '<rect x="700" y="700" width="200" height="100" fill="',
                    dirtbike.gasTank,
                    '" />'
                )
            );
    }

     function frontEnd(DirtBike memory dirtbike) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    // <!-- fork -->
                    '<rect x="900" y="800" width="100" height="100" fill="',
                    dirtbike.forks,
                    '" />'
                    '<rect x="1000" y="900" width="100" height="100" fill="',
                    dirtbike.forks,
                    '" />'
                    '<rect x="1100" y="1000" width="100" height="100" fill="',
                    dirtbike.forks,
                    '" />'

                    // <!-- handlebars -->
                    '<rect x="900" y="500" width="100" height="200" fill="',
                    dirtbike.handlebars,
                    '" />'
                    '<rect x="800" y="500" width="200" height="100" fill="',
                    dirtbike.handlebars,
                    '" />'

                )
            );
    }

    // Cool Cats Solidity — Random Numbers - https://medium.com/coinmonks/solidity-random-numbers-f54e1272c7dd
    function generateDirtBike(uint256 tokenId) public view returns (DirtBike memory dirtBike){
        uint256 psuedoRandomTokenHash = DirtBikesStorage.dirtBikeslayout().dirtBikeVIN[tokenId];
        // build an array of predefined length
        uint256[] memory vin = new uint256[](10);

        // iterate over the number of stats we want a random number for
        for (uint256 i; i < 10; i++) {
            // use random number to get number between 0 and maxStatValue
            vin[i] = psuedoRandomTokenHash % 10;
            // bit shift randomHash to the right 8 bits - can be fewer
            psuedoRandomTokenHash >>= 8;
        }

        DirtBike memory dirtBike = createDirtBikeStruct(vin);

        return dirtBike;
    }

    function generateAttributes(uint256 tokenId) public view returns (string memory){
        DirtBike memory dirtBike = generateDirtBike(tokenId);

        string memory metadata = generateMetadata(dirtBike);

        return metadata;
    }

    function generateDirtBikeSvg(uint256 tokenId) public view returns (string memory){
        // Build Dirt Bike Vin from random hash

        DirtBike memory dirtBike = generateDirtBike(tokenId);
        string memory dirtBikeSvg = '';

        dirtBikeSvg = string.concat(
                dirtBikeSvg,
                background(dirtBike),
                rearWheelSvg(dirtBike),
                frontWheelSvg(dirtBike),
                driveTrainSvg(dirtBike),
                body(dirtBike),
                frontEnd(dirtBike)
            );

        // SVG opening and closing tags
        string memory finalSvg = string(
            abi.encodePacked(
                '<svg viewBox="0 0 1600 1600" xmlns="http://www.w3.org/2000/svg">',
                dirtBikeSvg,
                "</svg>"
            )
        );

        return finalSvg;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        _exists(tokenId);

        return
          string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "Dirt Bikes #',
                            (tokenId).toString(),
                            '", "description": "Dirt Bikes Omnichain Diamond NFTs", ',
                            generateAttributes(tokenId),
                            ' "image":"data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateDirtBikeSvg(tokenId))),
                            '"}'
                        )
                    )
                )
            )
          );
    }
}
