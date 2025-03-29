// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error TransferFailed();
error NeedsMoreThanZero();
error WithdrawalPaused();
error InvalidStakingDuration();
error NoStakedTokens();
error StakingPeriodNotReached();
error RewardClaimingPaused();
// error LessThanMinStakeAmount();

contract StreamlivrStaking is ReentrancyGuard, Ownable {
    address constant penaltyWalletAddress = 0xd9Cad4552D89dAcAcA97Cbc843E39B13bA1F605a;

    IERC20 immutable stakingToken;
    IERC20 immutable rewardToken;

    uint256 totalStakedTokens;
    uint256 totalUsersRewards;
    
    uint256 public rewardRateFor30days = 2; // 3% for monthly staking
    uint256 public rewardRateFor1yr = 2; // 40% for yearly staking
    uint256 public rewardRateFor2yr = 4; // 85% for two-year staking

    uint256 stakePenaltyPercentage = 50; // A 50% stake Penalty for early unstaking

    uint256 constant MIN_STAKE_AMOUNT_MONTHLY = 10 * 1000000000000000000; // 10 tokens, assuming 18 decimals
    uint256 constant MIN_STAKE_AMOUNT_ANUALLY = 100 * 1000000000000000000; // 10 tokens, assuming 18 decimals

    mapping(address => uint256) userStakedTokens;
    mapping(address => uint256) userStakeDate;
    mapping(address => uint256) userStakeDuration;
    mapping(address => uint256) userRewards;
    mapping(address => bool) userTokenIsStaked;
    mapping(address => uint256) userRewardRate;

    bool public withdrawalPaused;
    bool public rewardClaimPaused;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);
    event PlanSwitched(address indexed user, uint256 newDuration);

    constructor(address _stakingToken, address _rewardToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    // ----------------- USER CORE ACTIONS ----------------------
    function stake(uint256 amount, uint256 durationInDays) external nonReentrant {
        if(durationInDays == 30) require(amount >= MIN_STAKE_AMOUNT_MONTHLY, "Minimum stake amount not met");
        else  require(amount >= MIN_STAKE_AMOUNT_ANUALLY, "Minimum stake amount not met");

        require(!userTokenIsStaked[msg.sender], "Already staking");

        uint256 rewardRate = getRewardRate(durationInDays);
        uint256 reward = calculateReward(amount, rewardRate);

        totalStakedTokens += amount;
        totalUsersRewards += reward;

        userStakedTokens[msg.sender] = amount;
        userStakeDate[msg.sender] = block.timestamp;
        userStakeDuration[msg.sender] = durationInDays;
        userRewards[msg.sender] += reward;
        userRewardRate[msg.sender] = rewardRate;
        userTokenIsStaked[msg.sender] = true;

        emit Staked(msg.sender, amount);

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
    }

    // Handle StakingPenalty which is dedution of staked amount to company's wallet and no claim rewards
    function unstake() external nonReentrant canUnstake {
        require(userTokenIsStaked[msg.sender], "No tokens staked");

        uint256 stakedAmount = userStakedTokens[msg.sender];
        userStakedTokens[msg.sender] = 0;
        userTokenIsStaked[msg.sender] = false;

        totalStakedTokens -= stakedAmount;

        emit Unstaked(msg.sender, stakedAmount);

        uint256 transferAmount;

        if(isSubscriptionOrStakingActive()) {
            transferAmount = ((stakedAmount * stakePenaltyPercentage) / 100);

            bool penaltyTransferSuccess = stakingToken.transfer(penaltyWalletAddress,  (stakedAmount - transferAmount));
            if(!penaltyTransferSuccess) revert TransferFailed();

            uint256 prevReward = userRewards[msg.sender];

            userRewards[msg.sender] = prevReward - calculateReward(stakedAmount, userRewardRate[msg.sender]);
        }else {
            transferAmount = stakedAmount;
        }

        userRewardRate[msg.sender] = 0;
        userStakeDuration[msg.sender] = 0;
        userStakeDate[msg.sender] = 0;

        bool success = stakingToken.transfer(msg.sender, transferAmount);
        if (!success) revert TransferFailed();
    }

    function claimReward() external nonReentrant {
        require(!rewardClaimPaused, "Reward claiming paused");
        require(!userTokenIsStaked[msg.sender], "Unstake tokens before claiming Reward");

        uint256 reward = userRewards[msg.sender];
        require(reward > 0, "No reward available");
        
        userRewards[msg.sender] = 0;

        totalUsersRewards -= reward;

        emit RewardsClaimed(msg.sender, reward);

        bool success = rewardToken.transfer(msg.sender, reward);
        if (!success) revert TransferFailed();
    }

    function getRewardRates() external view returns(uint256 reward30days, uint256 reward1yr, uint256 reward2yr) {
        return(rewardRateFor30days, rewardRateFor1yr, rewardRateFor2yr);
    }

    // function switchPlan(uint256 newDurationInDays) external nonReentrant {
    //     require(userTokenIsStaked[msg.sender], "No tokens staked");

    //     uint256 stakedAmount = userStakedTokens[msg.sender];

    //     uint256 oldRewardRate = userRewardRate[msg.sender];
    //     uint256 newRewardRate = getRewardRate(newDurationInDays);

    //     uint256 oldDuration = userStakeDuration[msg.sender];
    //     userStakeDuration[msg.sender] = newDurationInDays;
    //     userRewardRate[msg.sender] = newRewardRate;

    //     uint256 reward = calculateReward(stakedAmount, newRewardRate);

    //     if(!(isSubscriptionOrStakingActive())) {
    //         userRewards[msg.sender] += reward;
    //     }else {
    //         uint256 rewardForTheTimePeriodStaked = 
    //         stakedAmount 
    //         * ((oldRewardRate / 100) / (oldDuration * 1 days)) // reward rate calculation in decimals for a single second
    //         * (block.timestamp - userStakeDate[msg.sender]); // Number of seconds token has been staked before plan upgrade
    //         userRewards[msg.sender] = reward + rewardForTheTimePeriodStaked;
    //     }

    //     userStakeDate[msg.sender] = block.timestamp;
    //     totalUsersRewards += reward;

    //     emit PlanSwitched(msg.sender, newDurationInDays);
    // }

    // ------------------ ADMIN ---------------------------
    function fundRewardPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");

        bool success = rewardToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
    }

    function emptyRewardPool() external onlyOwner {
        bool success = rewardToken.transfer(penaltyWalletAddress, getRewardPoolBalance());
        if(!success) revert TransferFailed();
    }

    function updateRewardRates(uint256 _30days, uint256 _1yr, uint256 _2yrs) external onlyOwner {
        rewardRateFor30days = _30days;
        rewardRateFor1yr = _1yr;
        rewardRateFor2yr = _2yrs;
    }

    function setWithdrawalStatus(bool _value) external onlyOwner {
        withdrawalPaused = !_value;
    }

    function setRewardClaimStatus(bool _value) external onlyOwner {
        rewardClaimPaused = !_value;
    }

    function getWithdrawalStatus() external view onlyOwner returns(bool) {
        return withdrawalPaused;
    }

    function getRewardClaimStatus() external view onlyOwner returns(bool) {
        return rewardClaimPaused;
    }

    function getRewardPoolBalance() public view onlyOwner returns (uint256) {
        if(address(stakingToken) == address(rewardToken)) {
            return (rewardToken.balanceOf(address(this)) - totalStakedTokens);
        }else {
            return rewardToken.balanceOf(address(this));
        }
    }

    function getTotalEstimatedUsersRewards() external view  onlyOwner returns(uint256) {
        return totalUsersRewards;
    }

    function getTotalStakedAmount() external view onlyOwner returns(uint256) {
        return totalStakedTokens;
    }
    
    // --------------------------- HELPERS --------------------
    function getRewardRate(uint256 durationInDays) internal view returns (uint256) {
        if (durationInDays == 30) return rewardRateFor30days;
        if (durationInDays == 365) return rewardRateFor1yr;
        if (durationInDays == 730) return rewardRateFor2yr;
        revert InvalidStakingDuration();
    }

    function calculateReward(
        uint256 amount,
        uint256 rate
    ) internal pure returns (uint256) {
        return (amount * rate) / 100;
    }

    // -------------------------- MODIFIERS --------------------
    modifier canUnstake() {
        require(!withdrawalPaused, "Withdrawals are paused");
        _;
    }

    // --------------------------- Getters for user info ---------------------
    function getStakedAmount() external view returns (uint256) {
        return userStakedTokens[msg.sender];
    }

    function getRewardAmount() external view returns (uint256) {
        return userRewards[msg.sender];
    }

    function getStakingInfo() external view returns (uint256 stakedAmount, uint256 stakeDate, uint256 duration, uint256 rewardRate, string memory subscriptionPlan) {
        subscriptionPlan = "free";

        duration = userStakeDuration[msg.sender];

        if(duration == 30) {
            subscriptionPlan = "PRO";
        }else if(duration == 365) {
            subscriptionPlan = "PREMIUM";
        }

        return (userStakedTokens[msg.sender], userStakeDate[msg.sender], duration, userRewardRate[msg.sender], subscriptionPlan);
    }

    function isSubscriptionOrStakingActive() public view returns (bool) {
        return (block.timestamp < (userStakeDate[msg.sender] + (userStakeDuration[msg.sender] 
        * 1 days // Comment For test purpose, to run stacking durations in secondsv
        ))); // Returns false if staking time has been exceeded and requires a new stake to continue subscription

        // return true;
    }
}


// 000000000000000000
