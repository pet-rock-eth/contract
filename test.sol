// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyToken is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    struct Cat{
        uint id;
        uint adopt_date_timestamp;
        uint256 feed;
        uint256 healthPointPercentage_18digits;
    }
    mapping (uint256 => Cat) private tokenMutableData;
    
    constructor() ERC1155("https://ipfs.io/ipfs/bafybeibkrtttj2mtjmuwu26l7dlbmvt5k5qgah7qxmhobv3ps5j232tzdy/stone{id}.json") {
        Cat memory newcat = Cat(1, block.timestamp, 0, 0);
        _mint(msg.sender, newcat.id, 1,"");
        tokenMutableData[1] = newcat;
        newcat.healthPointPercentage_18digits = get_health_point_percentage(1);

        // uint i = 0;
        // while( i < 100){
        //     _mint(msg.sender, cats[i], 1,"");
        //     i++;
        // }
        
    }

    // function setURI(string memory newuri) private onlyOwner {
    //     _setURI(newuri);
    // }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        private
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        private
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 id) override public pure returns (string memory) {
        // require(r)
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/bafybeibkrtttj2mtjmuwu26l7dlbmvt5k5qgah7qxmhobv3ps5j232tzdy/stone",
                Strings.toString(id),".json"
            )
        );
    }

    function feed(uint256 id, uint feed_days) public {
        //require 超過100為100
        // 604800 -> 7天
        tokenMutableData[id].feed += feed_days * 86400 * 1e18 ;
        
    }

    function get_adopt_time(uint256 id) public view returns(uint hp){
        return tokenMutableData[id].adopt_date_timestamp;
    }

    function get_health_point_percentage(uint id) public view returns(uint256 health_digits18) {
        return divide(518400 - (block.timestamp - get_adopt_time(id)), 518400) + tokenMutableData[id].feed ;
    }
    function divide(uint256 a, uint256 b) public pure returns(uint256 int_one_to_digits18 ) {
    require(b != 0, "division by zero will result in infinity.");
        return (a * 1e18) / b;
    }
}