// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LivrToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("StreamLivr", "SLT") {
        _mint(msg.sender, initialSupply);
    }
}