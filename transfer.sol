// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC1155, Ownable{
    constructor() ERC1155(""){

    }

    function unlock_payment() public payable{
        address payable recipient = payable(owner()); // Get the address and cast it to payable
        require(recipient.send(msg.value)); // Problematic part: Transfer value
    }
}