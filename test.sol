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
        address adopter_address;
        uint adopt_date_timestamp;
        uint256 feed;
        uint256 healthPointPercentage_18digits;
    }

    uint nft_amounts = 1;
    mapping (uint256 => Cat) private tokenMutableData;
    
    constructor() ERC1155("https://ipfs.io/ipfs/bafybeibkrtttj2mtjmuwu26l7dlbmvt5k5qgah7qxmhobv3ps5j232tzdy/stone{id}.json") {
        while( nft_amounts <= 100){
            Cat memory newcat = Cat(nft_amounts, msg.sender, block.timestamp, 0, 0);
            _mint(msg.sender, newcat.id, 1, "cat");
            tokenMutableData[nft_amounts] = newcat;
            newcat.healthPointPercentage_18digits = get_health_point_percentage_or_burn(nft_amounts);
            nft_amounts++;
        }
        
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account_address, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    { 
        _mint(account_address, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal 
        override(ERC1155, ERC1155Supply)
    {
        require(to != address(0), "The address from reciever not exist!");   
        require(ids.length == amounts.length, "The length of IDs and amounts arrays must match!");
        for (uint256 i = 1; i < ids.length; i++) {
            require(balanceOf(from, ids[i]) == 1, "Insufficient balance for token ID");
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 id) override public view returns (string memory) {
        require(id <= nft_amounts, "The required ID is exceed this contract owned.");
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/bafybeibkrtttj2mtjmuwu26l7dlbmvt5k5qgah7qxmhobv3ps5j232tzdy/stone",
                Strings.toString(id),".json"
            )
        );
    }

    function feed(uint256 id, uint feed_days, address adopter) public {
        require(adopter == tokenMutableData[id].adopter_address, "The feeder is not adopter, your stone get angry.");
        // TBD: require 超過100為100
        // 604800 -> 7天
        // TBD: transfer fee get from feeder, may need to write another function about payable transfer.
        tokenMutableData[id].feed += feed_days * 86400 * 1e18 ;
        
    }

    function get_adopt_time(uint256 id) public view returns(uint){
        return tokenMutableData[id].adopt_date_timestamp;
    }

    function get_health_point_percentage_or_burn(uint id) public returns(uint256 health_digits18) {
        uint percentage = divide(5184000 - (block.timestamp - get_adopt_time(id)), 5184000) + tokenMutableData[id].feed ;
        if(percentage <= 0){
            _burn(tokenMutableData[id].adopter_address, id, 1);
        }

        return percentage;
    }
    function divide(uint256 a, uint256 b) private pure returns(uint256 int_one_to_digits18 ) {
        assert(b != 0);
        return (a * 1e18) / b;
    }
}