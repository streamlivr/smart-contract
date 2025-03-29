pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RewardSystem.sol";

contract DeployRewardContract is Script {
    function run() external {
        vm.startBroadcast();

        RewardContract rewardContract = new RewardContract(0x419D7b5eB52A30e080E304B20560618a847C6d42, 0xa0f4d2B02C2035035520486092bEf5bb747DeDB4);

        console.log("Reward Contract Address ", address(rewardContract));
        console.log("Reward Token Contract Address ", "0x419D7b5eB52A30e080E304B20560618a847C6d42");

        vm.stopBroadcast();
    }
}