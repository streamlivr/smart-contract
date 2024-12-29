// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./mock//Token.sol";
import '../src/Stacking2.sol';

contract StackingContractTest is Test {
    Token rewardToken;
    Token stakingToken;
    StreamlivrStaking stakingContract;

    uint256 constant INITIAL_SUPPLY = 1000000 * 1000000000000000000; // A million tokens formatted to ethers

    function setUp() public {
        // Deploy Reward and Staking Contracts to interact with the contract
        stakingToken = new Token(INITIAL_SUPPLY, "TestStakingToken", "TST");
        rewardToken = new Token(INITIAL_SUPPLY, "TestRewardToken", "TRT");

        // Deploy the staking contract
        stakingContract = new StreamlivrStaking(address(stakingToken), address(rewardToken));

        // Fund the reward Pool
        rewardToken.transfer(address(stakingContract), INITIAL_SUPPLY - 1000);

        // Transfer stacking tokens to this test contract to use for staking actions by the stacking contract
        stakingToken.transfer(address(this), INITIAL_SUPPLY);
    }

    function test_RewardPoolBalance() public {
        uint256 bal = rewardToken.balanceOf(address(stakingContract));
        assertEq(INITIAL_SUPPLY - 1000, bal);
    }

    function test_TestCobntractStakingTokenBalance() public {
        uint256 balance = stakingToken.balanceOf(address(this));
        assertEq(balance, INITIAL_SUPPLY);
    }

    function test_tokenStaking() public {
        uint256 amount =  10 * 1000000000000000000; // Calculating the decimals in ethers, 10 tokens to stake

        // Get the new Balance before staking action proceed
        uint256 prevBal = stakingToken.balanceOf(address(this));
        uint256 prevContractBal = stakingToken.balanceOf(address(stakingContract));

        // Approve this contract staking tokens spending by the test staking contract 
        stakingToken.approve(address(stakingContract), amount);
        stakingContract.stake(amount, 30);

        // Get the new Balance after staking action has been completed
        uint256 newBal = stakingToken.balanceOf(address(this));
        uint256 newContractBalance = stakingToken.balanceOf(address(stakingContract));

        assertEq((prevBal - amount), newBal, "User Balance After Staking Incorrect");
        assertEq((prevContractBal + amount), newContractBalance, "Staking Contract Balance After staking Incorrect");

        assertEq(stakingContract.getStakedAmount(), amount, "Staked amont tracking failed");
    }

    function test_minimumStakingAmountError() public {
        uint256 amount =  9.9 * 1000000000000000000; // Calculating the decimals, 100 tokens staked

        vm.expectRevert();
        // Test staking 9.9 tokens for 30 days when min stake amount for 30 days is 10 tokens
        stakingContract.stake(amount, 30);
    }

    function test_tokenUnstaking() public {
        uint256 min_stake_amount = 10 * 1000000000000000000;

        stakingToken.approve(address(stakingContract), min_stake_amount);
        stakingContract.stake(min_stake_amount, 30);

        uint256 prevBal = stakingToken.balanceOf(address(this));
        uint256 prevContractBal = stakingToken.balanceOf(address(stakingContract));

        skip(30 days); // Simulate time skip of 30 days

        stakingContract.unstake();

        uint256 newContractBal = stakingToken.balanceOf(address(stakingContract));
        uint256 newBal = stakingToken.balanceOf(address(this));

        assertEq(newBal, (prevBal + min_stake_amount) , "Staked tokens not returned to user");
        assertEq(prevContractBal - min_stake_amount, newContractBal, "Staked Tokens not deducted from contract");
    }

    function test_ustakingErrorWhenNoTokenIsStaked() public {
        uint256 amountStaked = stakingContract.getStakedAmount();
        if(amountStaked != 0) {
            stakingContract.unstake();
        } 

        vm.expectRevert();
        stakingContract.unstake();
    }

    function test_unstakingBeforeDueDatePenalty() public {
        uint256 amount =  10 * 1000000000000000000; // Calculating the decimals, 10 tokens staked
        
        uint256 userBalanceBeforeStaking = stakingToken.balanceOf(address(this));

        stakingToken.approve(address(stakingContract), amount);
        stakingContract.stake(amount, 30);

        stakingContract.unstake();

        uint256 userBalanceAfterUnstaking = stakingToken.balanceOf(address(this));
        uint256 expectedBalanceAfterUnstaking = (userBalanceBeforeStaking - ((amount * 50)/100)); // 50% penalty

        assertEq(userBalanceAfterUnstaking, expectedBalanceAfterUnstaking, "User wasn't penalized");
    }

    // function test_rewardClaimingWhenTheClaimingActionHasBeenPausedByTheAdmin() public {
    //     stakingContract.setRewardClaimStatus(false);

    //     // Returns true when rewardClaimingActions is Paused;
    //     if(stakingContract.getRewardClaimStatus()) {
            
    //     }
    // }

    function test_rewardClaiming() public {
        uint256 prevRewardBal = rewardToken.balanceOf(address(this));
        uint256 prevContractRewardPool = rewardToken.balanceOf(address(stakingContract));

        uint256 amount = 10 * 1000000000000000000;

        stakingToken.approve(address(stakingContract), amount);
        stakingContract.stake(amount, 30);

        skip(30 days);

        stakingContract.unstake();

        stakingContract.claimReward();

        uint256 newRewardBalance = rewardToken.balanceOf(address(this));
        uint256 newContractRewardPool = rewardToken.balanceOf(address(stakingContract));
        assertGt(newRewardBalance, prevRewardBal, "Reward Token Not Added to User Balance");
        assertGt(prevContractRewardPool, newContractRewardPool, "Reward Token not deducted from staking contract");
    }

    function test_getStackedAmount() public {
        uint256 amount = 1000 * 1000000000000000000;
        
        stakingToken.approve(address(stakingContract), amount);
        stakingContract.stake(amount, 30);

        uint256 stakedAmount = stakingContract.getStakedAmount();

        assertEq(amount, stakedAmount, "Failure to track user's staked tokemn amount");
    }

    function test_getRewardAmount() public {
        uint256 amount = 1000 * 1000000000000000000; // 1000 tokens to decimal
        stakingToken.approve(address(stakingContract), amount);
        stakingContract.stake(amount, 30);
        assertEq(stakingContract.getRewardAmount(), ((amount * 2) / 100), "Incorrect Reward calculated by contract");
    }

    function test_subscriptionIsExpired() public {
        uint256 amount = 1000 * 1000000000000000000;
        stakingToken.approve(address(stakingContract), amount);
        stakingContract.stake(amount, 30);
        assertEq(stakingContract.isSubscriptionOrStakingActive(), true, "Subscriptiob wasn't made or recorded");

        skip(30 days);

        assertEq(stakingContract.isSubscriptionOrStakingActive(), false, "Subscription didn't expire, It should have");
    }

    function test_fundRewardPool() public {
        if(address(this) == stakingContract.owner()) {
            rewardToken.approve(address(stakingContract), 100);
            
            uint256 amount = 10;

            uint256 prevBal = rewardToken.balanceOf(address(stakingContract));

            stakingContract.fundRewardPool(amount);

            uint256 newBal = rewardToken.balanceOf(address(stakingContract));

            assertEq(prevBal + amount, newBal, "No token sent to the smart contract");
        }
    }

    function test_setWithdrawStatusAndsetRewardClaimStatus() public {
        bool value = false;

        if(address(this) == stakingContract.owner()) {
            stakingContract.setRewardClaimStatus(value);
            stakingContract.setWithdrawalStatus(value);

            assertEq(stakingContract.getRewardClaimStatus(), !value, "Reward Claim Status wasn't set");
            assertEq(stakingContract.getWithdrawalStatus(), !value, "Withdraw or Unstake Status wasn't set");
        }
    }

    function test_updateRewardRates() public {
        uint256 rate30days = 5;
        uint256 rate1yr = 10;
        uint256 rate2yr = 20;

        stakingContract.updateRewardRates(rate30days, rate1yr, rate2yr);

        (uint256 rewardRate30days, uint256 rewardRate1yr, uint256 rewardRate2yrs) = stakingContract.getRewardRates();

        assertEq(rewardRate30days, rate30days, "The 30 days reward rate wasn't updated");
        assertEq(rewardRate1yr, rate1yr, "The 1 year reward rate wasn't updated");
        assertEq(rewardRate2yrs, rate2yr, "The 2 years reward rate wasn't updated");

    }
}
