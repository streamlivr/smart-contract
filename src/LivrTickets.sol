// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LivrToken is ERC20, Ownable {

    uint256 public constant MAX_SUPPLY = 1000000000 * 10 ** 18;

    constructor(uint256 initialSupply) ERC20("StreamLivr", "SLT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint (address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "LivrToken: MAX_SUPPLY_EXCEEDED");
        _mint(to, amount);
    }
}