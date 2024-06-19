// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LivrToken is ERC20Burnable, ERC20Permit, ERC20Votes, Ownable {
    error LivrToken_MustBeMoreThanZero();
    error LivrToken_BurnAmountExceedsBalance();
    error LivrToken_NotZeroAddress();
    error LivrToken_MaxSupplyExceeded();


    constructor() 
        ERC20("Streamlivr", "LIVR")
        Ownable(msg.sender)
        ERC20Permit("Streamlivr")
    {


        _mint(msg.sender, 20000000000000000000000000);
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

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert LivrToken_NotZeroAddress();
        }

        if (_amount <= 0) {
            revert LivrToken_MustBeMoreThanZero();
        }

        _mint(_to, _amount);
        return true;
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
