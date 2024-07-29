// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(uint256 initialSupply, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, initialSupply);
    }
}