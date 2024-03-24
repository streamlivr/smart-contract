// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

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

    uint256 public constant MAX_SUPPLY = 500000000 * 10 ** 18;

    constructor(uint256 initialSupply, address _to) ERC20("streamlivr", "STRV") Ownable(msg.sender) ERC20Permit("streamlivr") {
        if (_to == address(0)) {
            revert LivrToken_NotZeroAddress();
        }

        if (initialSupply <= 0) {
            revert LivrToken_MustBeMoreThanZero();
        }
        // Check token total supply plus initial supply is less than or equal to MAX_SUPPLY
        if (totalSupply() + initialSupply > MAX_SUPPLY) {
            revert LivrToken_MaxSupplyExceeded();
        }

        _mint(_to, initialSupply);
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

        // Check token total supply plus _amount is less than or equal to MAX_SUPPLY
        if (totalSupply() + _amount > MAX_SUPPLY) {
            revert LivrToken_MaxSupplyExceeded();
        }

        _mint(_to, _amount);
        return true;
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
