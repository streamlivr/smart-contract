// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../test/mock/Token.sol";
import "../src/Stacking2.sol";

contract DeployStakingScript is Script {
    function run() external {
        vm.startBroadcast();

        uint256 init_supply = 10000000000000000000000000000;
        Token livrToken = new Token(init_supply, "Test Token", "TT");

        StreamlivrStaking livrStakingContract = new StreamlivrStaking(address(livrToken), address(livrToken));

        console.log("Contract Token Address: ", address(livrToken));
        console.log("Contract Staking Address: ", address(livrStakingContract));

        vm.stopBroadcast();
    }
}