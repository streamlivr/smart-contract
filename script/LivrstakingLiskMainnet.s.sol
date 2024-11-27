// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../test/mock/Token.sol";
import "../src/Stacking2.sol";

contract DeployStakingScript is Script {
    function run() external {
        vm.startBroadcast();

        StreamlivrStaking livrStakingContract = new StreamlivrStaking(0xcDF71a48185145c205cb11e3E4aa60C1c1F7d675, 0xcDF71a48185145c205cb11e3E4aa60C1c1F7d675);

        console.log("Contract Token Address: ", 0xcDF71a48185145c205cb11e3E4aa60C1c1F7d675);
        console.log("Contract Staking Address: ", address(livrStakingContract));

        vm.stopBroadcast();
    }
}