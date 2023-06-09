// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyToken is ERC1155, Ownable, ERC1155Burnable{
    struct Stone{
        uint id;
        address adopter_address;
        uint adopt_date_timestamp;
        uint256 feed;
        uint256 healthPointPercentage_18digits;
        bool lock_status; //true is locked, otherwise it free
        bool live_status;
    }

    uint256 mintid = 0;
    uint256 transactionfee = 0.001 ether;
    mapping (address => uint256[]) address_to_stone;
    mapping (uint256 => Stone) private tokenMutableData; //id:stone
    event Received(address _sender, uint _value, string _message);

    constructor() ERC1155("https://ipfs.io/ipfs/bafybeibkrtttj2mtjmuwu26l7dlbmvt5k5qgah7qxmhobv3ps5j232tzdy/stone{id}.json") {

    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account_address)
        public
    {
        require(mintid <= 100,"the mint is end");
        mintid += 1;
        Stone memory newstone = Stone(mintid, account_address, block.timestamp, 0, 0, true, true);
        _mint(msg.sender, mintid, 1, "stone");
        tokenMutableData[mintid] = newstone;
        newstone.healthPointPercentage_18digits = get_health_point_percentage_or_burn(mintid);
        address_to_stone[account_address].push(mintid);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        for (uint i=0 ; i<ids.length ; i++){
            require(get_adopt_time(ids[i]) == 0 ,"this NFT has already mint");
            require(ids[i] <= 100 ,"the id is too big");
        }
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
        require(balanceOf(from, id) == 1, "Insufficient amount for token ID");
        require(tokenMutableData[id].lock_status == false, "The transaction pay still not done yet.");
        super.safeTransferFrom(from, to, id, amount, data);
        address_to_stone[to].push(id);
        delete address_to_stone[from][findstone_arrayposition(from,id)];
        tokenMutableData[id].lock_status = true;
    }
    
    function check_batch_lock (uint[] memory ids, bool status) public view returns(bool){

        for(uint256 i = 0 ; i < ids.length ; i++){
            require(tokenMutableData[ids[i]].lock_status == status,"your NFT status isn't correct.");
        }
        return true;
    }

    function set_batch_lock (uint[] memory ids, bool lock_status) public{
        for(uint256 i = 0 ; i < ids.length ; i++){
            tokenMutableData[ids[i]].lock_status = lock_status;
        }
    }

    function get_lock_status(uint id) public view returns(bool){
        if(tokenMutableData[id].lock_status == true){
            return true;
        }else{
            return false;
        }
    }

    function check_locked (uint id) public view returns(bool){
        require(tokenMutableData[id].lock_status == true,"your NFT status isn't correct.");
        return true;
    }

    function unlock_payment(uint id) public payable{
        require(msg.value >= transactionfee, "Insufficient bid.");
        require(tokenMutableData[id].lock_status == true, "the NFT already unlock");
        emit Received(msg.sender,msg.value,"the lock is update");
        tokenMutableData[id].lock_status = false;
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

    function get_feed(uint id) public view returns(uint){
        return tokenMutableData[id].feed;
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
            tokenMutableData[id].live_status = false;
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

    function findstone(address account) public view returns(uint256[] memory){
        return address_to_stone[account];
    }

    function findstone_arrayposition(address account,uint256 id) private view returns(uint256 position){
        for (uint256 i=0 ; i < findstone(account).length ; i++){
            if(address_to_stone[account][i] == id){
                return i;
            }
        }
    }

    function get_struct(uint id) public view returns(Stone memory){
        return tokenMutableData[id];
    }
}
