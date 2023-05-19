// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MyTokenERC1155 is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    constructor() ERC1155("https://ipfs.io/ipfs/bafybeibkrtttj2mtjmuwu26l7dlbmvt5k5qgah7qxmhobv3ps5j232tzdy/stone{id}.json") {
        _mint(msg.sender,1,1,"");
        _mint(msg.sender,2,1,"");
    }
    uint256 transactionfee = 0.001 ether;
    mapping (address => uint) allowednumber;
    event Received(address _sender, uint _value, string _message);

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
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
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function getallowednumber(address from) public view returns(uint){
        return allowednumber[from];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override{
        if (getallowednumber(from)>=1){
            allowednumber[from] = allowednumber[from] - 1;
            super.safeTransferFrom(from, to, id, amount, data);
        }else{
            revert();
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        if (getallowednumber(from)>=1){
            allowednumber[from] = allowednumber[from] - 1;
            super.safeBatchTransferFrom(from, to, ids, amounts, data);
        }else{
            revert();
        }
        
    }

    //增加可交易次數，number為增加之次數
    function addallowednumber(uint number) public payable{
        if(allowednumber[msg.sender] + number >= allowednumber[msg.sender]){
            uint transfernumber = number * transactionfee;
            allowednumber[msg.sender] += number;
            emit Received(msg.sender,transfernumber,"the allowed number is update");
        }
    }

    //若有人匯入(N)個0.001ETH則增加N次可轉換次數
    fallback () external payable {          //若msg.data為空則執行fallback
        if (msg.value >= transactionfee 
        && allowednumber[msg.sender] + (msg.value/transactionfee) > allowednumber[msg.sender]
        ){
            allowednumber[msg.sender] = allowednumber[msg.sender] + (msg.value/transactionfee);
            emit Received(msg.sender, msg.value, "fallback was called");        //接收ETH
        }else{
            revert();
        }
    }

    //若有人匯入(N)個0.001ETH則增加N次可轉換次數
    receive () external payable{          //若msg.data不為空則執行receive
        if (msg.value >= transactionfee 
        && allowednumber[msg.sender] + (msg.value/transactionfee) > allowednumber[msg.sender]
        ){
            allowednumber[msg.sender] = allowednumber[msg.sender] + (msg.value/transactionfee);
            emit Received(msg.sender, msg.value, "fallback was called");        //接收ETH
        }else{
            revert();
        }
    }
}
