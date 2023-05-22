// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyToken is ERC1155, Ownable, ERC1155Burnable{
    struct Cat{
        uint id;
        address adopter_address;
        uint adopt_date_timestamp;
        uint256 feed;
        uint256 healthPointPercentage_18digits;
        bool lock_status; //true is locked, otherwise it free
    }

    uint256 transactionfee = 0.001 ether;
    mapping (uint256 => Cat) private tokenMutableData; //id:cat
    event Received(address _sender, uint _value, string _message);

    constructor() ERC1155("https://ipfs.io/ipfs/bafybeibkrtttj2mtjmuwu26l7dlbmvt5k5qgah7qxmhobv3ps5j232tzdy/stone{id}.json") {

    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account_address, uint256 id)
        public
    { 
        Cat memory newcat = Cat(id, account_address, block.timestamp, 0, 0, true);
        _mint(msg.sender, id, 1, "cat");
        tokenMutableData[id] = newcat;
        newcat.healthPointPercentage_18digits = get_health_point_percentage_or_burn(id);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
            
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override{
        require(balanceOf(from, id) == 1, "Insufficient balance for token ID");
        require(tokenMutableData[id].lock_status == false, "The transaction pay still not done yet.");
        super.safeTransferFrom(from, to, id, amount, data);
    }
    
    function check_batch_lock (uint[] memory ids, bool status) private view returns(bool){

        for(uint256 i = 0 ; i < ids.length ; i++){
            require(tokenMutableData[ids[i]].lock_status == status,"your NFT status isn't correct.");
        }
        return true;
    }

    function set_batch_lock (uint[] memory ids, bool lock_status) private{
        for(uint256 i = 0 ; i < ids.length ; i++){
            tokenMutableData[ids[i]].lock_status = lock_status;
        }
    }

    function unlock_payment(uint id) public payable{
        emit Received(msg.sender,msg.value,"the lock is update");
        require(msg.value >= transactionfee, "Insufficient bid.");
        tokenMutableData[id].lock_status == false;
    }

    /*
    //expected it doesn't work porperly.
    function unlock_transfer( address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data)
        public returns(bool result) {
            unlock_payment(id);
            require(tokenMutableData[id].lock_status == false, "false while unlock the payment");
            safeTransferFrom(from, to, id, amount, data); //transfer
            return tokenMutableData[id].lock_status;
    }
    */

    function uri(uint256 id) override public view returns (string memory) {
        require(tokenMutableData[id].adopter_address != address(0), "The required ID is not this contract owned.");
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
    
    function get_token_adopter(uint id) public view returns(address adopter){
        return tokenMutableData[id].adopter_address;
    }
}