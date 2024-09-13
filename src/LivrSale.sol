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
    error LivrSale__SalePaused();
    error LivrSale__NotAllowedToClaim();
    /////////////////////
    // State variables //
    /////////////////////

    uint256 public constant USD_TO_LIVR_RATE = 116279000000000000000; // 1 USDT = 116.279 $LIVR
    uint96 public constant CLAIM_PERCENTAGE = 20;
    IERC20 public immutable i_usdToken;
    IERC20 public immutable i_livrToken;
    address public s_receiver;
    uint256 public constant MINIMUM_SALE_AMOUNT = 10 ether;
    uint256 public constant MAXIMUM_SALE_AMOUNT = 20000 ether;
    bool public s_claimable; 
    bool public s_pauseSale;
    bool public s_claimPercentage;

    mapping(address depositor => uint256) public totalPurchased;
    mapping(address depositor => uint256) public totalClaimed;


    /////////////////////
    // Events        ///
    ////////////////////

    event SaleMade(uint256 usdAmount, uint256 livrSold, address indexed user);
    event TokensClaimed(address user, uint256 amount);

    /////////////////////
    // Functions       //
    /////////////////////

    constructor(address _usdContractAddress, address _livrContractAddress, address receiver) Ownable(msg.sender) {
        i_usdToken = IERC20(_usdContractAddress);
        i_livrToken = IERC20(_livrContractAddress);
        s_receiver = receiver;
    }

    ////////////////////////
    // External Functions //
    ///////////////////////

    function updatePause() external onlyOwner {
        s_pauseSale = !s_pauseSale;
    }

    function updateClaimStatus(bool useClaimPercentage, bool claimable) external onlyOwner {
        s_claimable = claimable;
        s_claimPercentage = useClaimPercentage;
    }

    function updateReceiver(address newReceiver) external onlyOwner {
        s_receiver = newReceiver;
    }

    function claimTokens() external {
        if (!s_claimable) {
            revert LivrSale__NotAllowedToClaim();
        }

        uint256 purchased = totalPurchased[msg.sender];
        uint256 claimed = totalClaimed[msg.sender];
        
        require(purchased > claimed, "All tokens have been claimed");
        
        // Calculate 20% of the total purchased tokens
        uint256 claimAmount;
        if (s_claimPercentage) {
            
            claimAmount = (purchased * CLAIM_PERCENTAGE) / 100;
        } else {
            claimAmount = purchased - claimed;
        }

        // Ensure they can't claim more than the remaining amount
        if (claimed + claimAmount > purchased) {
            claimAmount = purchased - claimed;
        }
        
        // Update the claimed amount
        totalClaimed[msg.sender] += claimAmount;

        // Transfer the tokens (pseudo-code, assuming you have a transfer function)
        // token.transfer(msg.sender, claimAmount);
        
        // Emit an event (optional)
        emit TokensClaimed(msg.sender, claimAmount);
    }



    // Withdrawal

    function withdraw () external onlyOwner {
        uint256 balance = i_livrToken.balanceOf(address(this));

        require(balance > 0);

        bool tokenTransfered = i_livrToken.transfer(s_receiver, balance);
        require(tokenTransfered, "Token transfer failed");
    }

    ////////////////////////
    // Public Functions //
    ///////////////////////

    function buy(uint256 usdAmount) public nonReentrant {

        require(address(msg.sender).code.length == 0, "Contracts are prohibited");

        if (!s_pauseSale) {
            revert LivrSale__SalePaused();
        }

        if (usdAmount < MINIMUM_SALE_AMOUNT) {
            revert LivrSale__BelowMinimumSaleAmount();
        }
        if (usdAmount > MAXIMUM_SALE_AMOUNT) {
            revert LivrSale__AboveMaximumSaleAmount();
        }

        if (i_usdToken.balanceOf(msg.sender) < usdAmount) {
            revert LivrSale__NotEnoughTokenBalance();
        }


        // Calculate how much $livr user gets
        uint256 totalLivr = calculateSale(usdAmount);
        require(totalLivr > 0, "Calculate sale did not return a value");
        if (i_livrToken.balanceOf(address(this)) < totalLivr) {
            revert LivrSale__NotEnoughTokenBalance();
        }

        // Add user to investors mapping
        totalPurchased[msg.sender] += totalLivr;

        // Transfer value
        bool paid = i_usdToken.transferFrom(msg.sender, s_receiver, usdAmount);
        require(paid, "USD token transfer failed");

        emit SaleMade(usdAmount, totalLivr, msg.sender);
    }

    function calculateSale(uint256 usdtAmount) public pure returns (uint256) {
        if (usdtAmount >= 10 ** 18) {
            // usdtAmount is in wei
            return (usdtAmount * USD_TO_LIVR_RATE) / 10 ** 18;
        } else {
            // usdtAmount is in ether
            return usdtAmount * USD_TO_LIVR_RATE;
        }
    }
}
