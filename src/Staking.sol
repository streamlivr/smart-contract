//   // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// error TransferFailed();
// error NeedsMoreThanZero();
// error WithdrawalPaused();

// contract Staking is ReentrancyGuard, Ownable {
//     IERC20 public immutable s_rewardsToken;
//     IERC20 public immutable s_stakingToken;

//     // This is the reward token per second
//     // Which will be multiplied by the tokens the user staked divided by the total
//     // This ensures a steady reward rate of the platform
//     // So the more users stake, the less for everyone who is staking.
//     uint256 public s_reward30days = 100;
//     uint256 public s_reward1yr = 100;
//     uint256 public s_reward2yrs = 100;
//     uint256 public s_lastUpdateTime;
//     uint256 public s_rewardPerTokenStored;
//     bool public s_pauseWithdrawal;

//     mapping(address => uint256) public s_userRewardPerTokenPaid;
//     mapping(address => uint256) public s_rewards;

//     uint256 private s_totalSupply;
//     mapping(address => uint256) public s_balances;

//     event Staked(address indexed user, uint256 indexed amount);
//     event WithdrewStake(address indexed user, uint256 indexed amount);
//     event RewardsClaimed(address indexed user, uint256 indexed amount);

//     constructor(address stakingToken, address rewardsToken)  Ownable(msg.sender) {
//         s_stakingToken = IERC20(stakingToken);
//         s_rewardsToken = IERC20(rewardsToken);
//     }

//     /**
//      * @notice How much reward a token gets based on how long it's been in and during which "snapshots"
//      */
//     function rewardPerToken(uint256 REWARD_RATE) public view returns (uint256) {
//         if (s_totalSupply == 0) {
//             return s_rewardPerTokenStored;
//         }
//         return
//             s_rewardPerTokenStored +
//             (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
//     }

//     /**
//      * @notice How much reward a user has earned
//      */
//     function earned(address account) public view returns (uint256) {
//         return
//             ((s_balances[account] * (rewardPerToken() - s_userRewardPerTokenPaid[account])) /
//                 1e18) + s_rewards[account];
//     }

//     /**
//      * @notice Deposit tokens into this contract
//      * @param amount | How much to stake
//      */
//     function stake(uint256 amount)
//         external
//         updateReward(msg.sender)
//         nonReentrant
//         moreThanZero(amount)
//     {
//         s_totalSupply += amount;
//         s_balances[msg.sender] += amount;
//         emit Staked(msg.sender, amount);
//         bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
//         if (!success) {
//             revert TransferFailed();
//         }
//     }

//     /**
//      * @notice Withdraw tokens from this contract
//      * @param amount | How much to withdraw
//      */
//     function withdraw(uint256 amount) external updateReward(msg.sender) nonReentrant {
//         s_totalSupply -= amount;
//         s_balances[msg.sender] -= amount;
//         emit WithdrewStake(msg.sender, amount);
//         bool success = s_stakingToken.transfer(msg.sender, amount);
//         if (!success) {
//             revert TransferFailed();
//         }
//     }

//     /**
//      * @notice User claims their tokens
//      */
//     function claimReward() external updateReward(msg.sender) nonReentrant {
//         uint256 reward = s_rewards[msg.sender];
//         s_rewards[msg.sender] = 0;
//         emit RewardsClaimed(msg.sender, reward);
//         bool success = s_rewardsToken.transfer(msg.sender, reward);
//         if (!success) {
//             revert TransferFailed();
//         }
//     }

//     function updatewithdrawalStatus (bool _value) external onlyOwner returns(bool) {
//       s_pauseWithdrawal = _value;
//       return s_pauseWithdrawal;
//     }

//     function updateRewardRates(uint256 reward30day, uint256 reward1yr, uint256 reward2yrs) external onlyOwner {
//       s_reward1yr = reward1yr;
//       s_reward30days = reward30day;
//       s_reward2yrs = reward2yrs;
//     }

//     /********************/
//     /* Modifiers Functions */
//     /********************/
//     modifier updateReward(address account) {
//         s_rewardPerTokenStored = rewardPerToken();
//         s_lastUpdateTime = block.timestamp;
//         s_rewards[account] = earned(account);
//         s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
//         _;
//     }

//     modifier moreThanZero(uint256 amount) {
//         if (amount == 0) {
//             revert NeedsMoreThanZero();
//         }
//         _;
//     }

//     modifier canWithdraw(uint256 amount) {
//         if (s_pauseWithdrawal) {
//             revert WithdrawalPaused();
//         }
//         _;
//     }

//     /********************/
//     /* Getter Functions */
//     /********************/
//     // Ideally, we'd have getter functions for all our s_ variables we want exposed, and set them all to private.
//     // But, for the purpose of this demo, we've left them public for simplicity.

//     function getStaked(address account) public view returns (uint256) {
//         return s_balances[account];
//     }
// }
