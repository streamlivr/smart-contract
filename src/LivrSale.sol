// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract LivrSale is Ownable, ReentrancyGuard {
    //////////////
    // Errors //
    /////////////
    error LivrSale__BelowMinimumSaleAmount();
    error LivrSale__AboveMaximumSaleAmount();
    error LivrSale__NotEnoughTokenBalance();
    /////////////////////
    // State variables //
    /////////////////////

    uint256 public constant USD_TO_LIVR_RATE = 116279000000000000000; // 1 USDT = 116.279 $LIVR
    address immutable i_usdContratAddress;
    address immutable i_livrContractAddress;
    address public s_receiver = 0x1b6570e96E942678f3Ad9BB53D7BbDaE28E9A91e;
    uint256 public constant MINIMUM_SALE_AMOUNT = 50;
    uint256 public constant MAXIMUM_SALE_AMOUNT = 20000;

    bool public s_pause = false;

    /////////////////////
    // Events        ///
    ////////////////////

    event SaleMade(uint256 usdAmount, uint256 livrSold, address indexed user);

    /////////////////////
    // Functions       //
    /////////////////////

    constructor(address _usdContractAddress, address _livrContractAddress) Ownable(msg.sender) {
        i_usdContratAddress = _usdContractAddress;
        i_livrContractAddress = _livrContractAddress;
    }

    ////////////////////////
    // External Functions //
    ///////////////////////

    function calculateSale(uint256 usdtAmount) public pure returns (uint256) {
        return (usdtAmount * USD_TO_LIVR_RATE);
    }

    function updatePause() external onlyOwner {
        s_pause = !s_pause;
    }

    function buy(uint256 usdAmount) external payable nonReentrant {
        if (usdAmount < MINIMUM_SALE_AMOUNT) {
            revert LivrSale__BelowMinimumSaleAmount();
        }
        if (usdAmount > MAXIMUM_SALE_AMOUNT) {
            revert LivrSale__AboveMaximumSaleAmount();
        }

        if (IERC20(i_usdContratAddress).balanceOf(msg.sender) < usdAmount) {
            revert LivrSale__NotEnoughTokenBalance();
        }
        IERC20 usdToken = IERC20(i_usdContratAddress);
        IERC20 livrToken = IERC20(i_livrContractAddress);

        // Calculate how much $livr user gets
        uint256 totalLivr = calculateSale(usdAmount);

        // Transfer value
        usdToken.transferFrom(msg.sender, s_receiver, usdAmount);

        livrToken.transferFrom(address(this), msg.sender, totalLivr);

        emit SaleMade(usdAmount, totalLivr, msg.sender);
    }

    function updateReceiver (address newReceiver) external onlyOwner{
        s_receiver = newReceiver;
    }
}
