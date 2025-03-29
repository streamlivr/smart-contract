// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RewardContract is Ownable {
    address public backendSigner;
    IERC20 private immutable rewardToken;
    mapping (address => uint256) private nonces;
    mapping (address => uint256) rewards;
    mapping (address => uint256) accumulatedRewards;
    mapping (address => uint256) claimTimestamp;
    uint256 private tokenDecimal = 1000000000000000000; // ie 18 decimals;
    uint256 private minFirstClaimAmount = 10 * tokenDecimal;
    uint256 private claimingDuration = 30 days;
    address[] private users;

    constructor(address _rewardToken, address _backendSigner) Ownable(msg.sender) {
        rewardToken = IERC20(_rewardToken);
        backendSigner = _backendSigner;
    }

    function getNonce(address _account) external view returns (uint256){
        // Check if request is made by the backend signer or the owner of the contract;
        require((msg.sender == backendSigner) || (msg.sender == owner()), "Unauthorized Rewarder");

        return nonces[_account];
    }

    function rewardUser(uint256 nonce, uint256 amount, address userAddress, bytes calldata signature) public returns (bool) {
        require(userAddress != address(0));  

        // Verify that the signer is either backend or the claimer
        require((msg.sender == backendSigner) || (msg.sender == userAddress), "Unauthorized Rewarder");

        bool isMember = false;
        for (uint256 i; i < users.length; i++) 
        {
            if(users[i] == userAddress) {
                isMember = true;
                break;
            }
        }

        if(isMember == false) {
            users.push(userAddress);
        }
                
        //Verify the User custom Nonce;
        require((nonces[userAddress] == nonce), "Invalid Nonce");

        // Verify TransactionCallr is backendSigner

        // Hash The Message to validate
        bytes32 hashedMessage = keccak256(abi.encodePacked(nonces[userAddress], amount, userAddress));

        //Hash the Message with a signature
        bytes32 signedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedMessage));

        // Verify the signature was generated from the backend
        require((recoverSigner(signedMessage, signature) == backendSigner), "Unauthorized Signature");

        // Update User Reward
        rewards[userAddress] += amount;
        accumulatedRewards[userAddress] += amount;

        nonces[userAddress] += 1;

        return true;
    }

    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = unpackSignature(signature);
        address revoveredAddress = ecrecover(hash, v, r, s);
        return revoveredAddress;
    }

    function unpackSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature");
        assembly {
            r:= mload(add(signature, 32)) // Load the first 32 bytes from the given signature
            s:= mload(add(signature, 64)) // Load the second 32 bytes from the given signature
            v:= byte(0, mload(add(signature, 96))) // Load the last 1 byte of the signature
        }
    }

    function claimReward(address claimer) public returns (bool) {
        require(claimer != address(0));  

        // Verify that the signer is either backend or the claimer
        require((msg.sender == backendSigner) || (msg.sender == claimer), "Unauthorized Claimer");

        if(claimTimestamp[claimer] == 0) { // That is users first reward  claim
            require(rewards[claimer] >= minFirstClaimAmount, string.concat("Not enough rewards to claim, atleast ", Strings.toString(minFirstClaimAmount/tokenDecimal), " tokens is required"));
        }else{
            require(block.timestamp >= (claimTimestamp[claimer] + claimingDuration), string.concat("Reward claiming occurs every ", Strings.toString(claimingDuration/1 days), " days"));
        }

        require(rewards[claimer] > 0, "Can't claim 0 reward tokens");

        require(rewardToken.balanceOf(address(this)) >= rewards[claimer], "Not Enough tokens in reward Pool, try again later");

        bool transferSuccess = rewardToken.transfer(claimer, rewards[claimer]);

        rewards[claimer] = 0;
        claimTimestamp[claimer] = block.timestamp;

        return transferSuccess;
    }

    function getUserRewards(address _userAddress) public view returns (uint256) {
        // Verify that the user calling is either the contract owner or owner of reward
        require((msg.sender == backendSigner) || (msg.sender == _userAddress) || (msg.sender == owner()), "Unauthorized Account");

        return rewards[_userAddress];
    }

    function getTotalAccumulatedRewards(address userAddress) external view onlyOwner returns (uint256) {
        require(userAddress != address(0));  
        return (accumulatedRewards[userAddress]); // Returns the number of tokens as a float in base 18 decimals;  
    }

    function getUsers() external view returns (address[] memory addresses) {
        require((msg.sender == backendSigner) || (msg.sender == owner()), "Unauthorized Account");
        return users;
    }

    function setMinAmtForFirstClaim(uint256 _amount) external returns (bool) {
        require((msg.sender == backendSigner) || (msg.sender == owner()), "Unauthorized Account");
        minFirstClaimAmount = _amount;
        return true;
    }

    function getMinAmtForFirstClaim() external view returns (uint256) {
        require((msg.sender == backendSigner) || (msg.sender == owner()), "Unauthorized Account");
        return minFirstClaimAmount;
    }

    function getBackendSigner() onlyOwner external view returns(address) {
        return backendSigner;
    }

    function setBackendSigner(address _backendSigner) onlyOwner external {
        backendSigner = _backendSigner;
    }
}