// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./mock//Token.sol";
import '../src/Stacking2.sol';

contract StackingContractTest is Test {
    Token rewardToken;
    Token stakingToken;
    StreamlivrStaking stakingContract;

    uint256 constant INITIAL_SUPPLY = 1000000 ;

    function setUp() public {
        // Deploy Reward and Staking Contracts to interact with the contract
        stakingToken = new Token(INITIAL_SUPPLY, "TestStakingToken", "TST");
        rewardToken = new Token(INITIAL_SUPPLY, "TestRewardToken", "TRT");

        // Deploy the staking contract
        stakingContract = new StreamlivrStaking(address(stakingToken), address(rewardToken));

        // Fund thee reward Pool
        rewardToken.transfer(address(stakingContract), INITIAL_SUPPLY);

        // Approve the transfer of stacking tokens by the stacking contract
        stakingToken.approve(address(stakingContract), INITIAL_SUPPLY);
    }

    function test_RewardPoolBalance() public {
        uint256 bal = rewardToken.balanceOf(address(stakingContract));
        assertEq(INITIAL_SUPPLY, bal);
    }

    function test_stakingAllowance() public {
        uint256 allowance = stakingToken.allowance(address(this), address(stakingContract));
        assertEq(allowance, INITIAL_SUPPLY);
    }

    function test_tokenStaking() public {
        uint256 amount =  100 ; // Calculating the decimals, 100 tokens staked

        uint256 prevBal = stakingToken.balanceOf(address(this));
        uint256 prevContractBal = stakingToken.balanceOf(address(stakingContract));
        stakingContract.stake(amount, 30);
        uint256 newBal = stakingToken.balanceOf(address(this));
        uint256 newContractBalance = stakingToken.balanceOf(address(stakingContract));

        assertEq((prevBal - amount), newBal, "User Balance After Staking Incorrect");
        assertEq((prevContractBal + amount), newContractBalance, "Staking Contract Balance After staking Incorrect");

        assertEq(stakingContract.getStakedAmount(), amount, "Staked amont tracking failed");
    }

    function test_tokenUnstaking() public {
        uint256 min_stake_amount = 10;

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

    function test_rewardClaiming() public {
        uint256 prevRewardBal = rewardToken.balanceOf(address(this));
        uint256 prevContractRewardPool = rewardToken.balanceOf(address(stakingContract));

        stakingContract.stake(100, 30);
        skip(30 days);
        stakingContract.unstake();

        stakingContract.claimReward();

        uint256 newRewardBalance = rewardToken.balanceOf(address(this));
        uint256 newContractRewardPool = rewardToken.balanceOf(address(stakingContract));
        assertGt(newRewardBalance, prevRewardBal, "Reward Token Not Added to User Balance");
        assertGt(prevContractRewardPool, newContractRewardPool, "Reward Token not deducted from staking contract");
    }

    function test_getStackedAmount() public {
        uint256 amount = 1000;
        stakingContract.stake(amount, 30);

        uint256 stakedAmount = stakingContract.getStakedAmount();

        assertEq(amount, stakedAmount, "Failure to track user's staked tokemn amount");
    }
}