// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LivrToken is ERC20Burnable, Ownable {
    error LivrToken_MustBeMoreThanZero();
    error LivrToken_BurnAmountExceedsBalance();
    error LivrToken_NotZeroAddress();

    uint256 public constant MAX_SUPPLY = 1000000000 * 10 ** 18;

    constructor(uint256 initialSupply) ERC20("StreamLivr", "STRV") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert LivrToken_MustBeMoreThanZero();
        }

        if (balance < _amount) {
            revert LivrToken_BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    function mint (address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert LivrToken_NotZeroAddress();
        }

        if (_amount <= 0) {
            revert LivrToken_MustBeMoreThanZero();
        }

        _mint(_to, _amount);
        return true;
    }

    
}