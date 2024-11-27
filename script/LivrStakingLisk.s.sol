// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../test/mock/Token.sol";
import "../src/Stacking2.sol";

contract DeployStakingScript is Script {
    function run() external {
        vm.startBroadcast();

        StreamlivrStaking livrStakingContract = new StreamlivrStaking(0x419D7b5eB52A30e080E304B20560618a847C6d42, 0x419D7b5eB52A30e080E304B20560618a847C6d42);

        console.log("Contract Token Address: ", 0x419D7b5eB52A30e080E304B20560618a847C6d42);
        console.log("Contract Staking Address: ", address(livrStakingContract));

        vm.stopBroadcast();
    }
}