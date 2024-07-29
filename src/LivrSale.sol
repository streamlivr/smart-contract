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
    IERC20 public immutable i_usdToken;
    IERC20 public immutable i_livrToken;
    address public s_receiver = 0x1b6570e96E942678f3Ad9BB53D7BbDaE28E9A91e;
    uint256 public constant MINIMUM_SALE_AMOUNT = 10 ether;
    uint256 public constant MAXIMUM_SALE_AMOUNT = 20000 ether;

    bool public s_pause = false;

    /////////////////////
    // Events        ///
    ////////////////////

    event SaleMade(uint256 usdAmount, uint256 livrSold, address indexed user);

    /////////////////////
    // Functions       //
    /////////////////////

    constructor(address _usdContractAddress, address _livrContractAddress) Ownable(msg.sender) {
        i_usdToken = IERC20(_usdContractAddress);
        i_livrToken = IERC20(_livrContractAddress);
    }

    ////////////////////////
    // External Functions //
    ///////////////////////

    function calculateSale(uint256 usdtAmount) public pure returns (uint256) {
        if (usdtAmount >= 10**18) {
            // usdtAmount is in wei
            return (usdtAmount * USD_TO_LIVR_RATE) / 10**18;
        } else {
            // usdtAmount is in ether
            return usdtAmount * USD_TO_LIVR_RATE;
        }
    }

    function updatePause() external onlyOwner {
        s_pause = !s_pause;
    }

    function buy(uint256 usdAmount) public nonReentrant {
        if (usdAmount < MINIMUM_SALE_AMOUNT) {
            revert LivrSale__BelowMinimumSaleAmount();
        }
        if (usdAmount > MAXIMUM_SALE_AMOUNT) {
            revert LivrSale__AboveMaximumSaleAmount();
        }

        if (i_usdToken.balanceOf(msg.sender) < usdAmount) {
            revert LivrSale__NotEnoughTokenBalance();
        }

        // Ensure the contract has enough allowance
        uint256 allowance = i_usdToken.allowance(msg.sender, address(this));
        require(allowance >= usdAmount, "Allowance is not sufficient");

        // Calculate how much $livr user gets
        uint256 totalLivr = calculateSale(usdAmount);
        require(totalLivr > 0, "Calculate sale did not return a value");
        if (i_livrToken.balanceOf(address(this)) < totalLivr) {
            revert LivrSale__NotEnoughTokenBalance();
        }



        // Transfer value
        bool paid = i_usdToken.transferFrom(msg.sender, s_receiver, usdAmount);
        require(paid, "USD token transfer failed");
        // Transfer $livr token to user
        bool tokenTransfered = i_livrToken.transfer(msg.sender, totalLivr);
        require(tokenTransfered, "Token transfer failed");


        emit SaleMade(usdAmount, totalLivr, msg.sender);
    }

    // Withdrawal

    function updateReceiver (address newReceiver) external onlyOwner{
        s_receiver = newReceiver;
    }
}
