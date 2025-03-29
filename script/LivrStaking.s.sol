// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../test/mock/Token.sol";
import "../src/Stacking2.sol";

// Deploying to Metis Test Net
contract DeployStakingScript is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        // uint256 init_supply = 10000000000000000000000000000;
        // Token livrToken = new Token(init_supply, "Test Token", "TT");

        // StreamlivrStaking livrStakingContract = new StreamlivrStaking(address(livrToken), address(livrToken));

        // address OnlyLayerLIVRContravtAddress = 0xE4D351005fDDecce8310160fB6e65D0c74f809Ea;// testneet livr tokens for only layer
        // address LiskMainnetLIVRContractAddress = 0xcDF71a48185145c205cb11e3E4aa60C1c1F7d675;
        // address LiskTestnetLIVRContractAddress = 0x419D7b5eB52A30e080E304B20560618a847C6d42;
        // address MetisTestNativeTokenContractAddress = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;
        // address MetisTestRewardTokenContractAddress = 0x46F83b60491bce16B6c7a28de84eEeEEDE996E5F;
        // address MetisMainnerNativeTokenContractAddress = ;
        address MintTestnetLIVRContractAddress = 0x7232410DFb258582Ec722287a74274e62002d9d8;


        StreamlivrStaking livrStakingContract = new StreamlivrStaking(MintTestnetLIVRContractAddress, MintTestnetLIVRContractAddress);

        console.log("Contract Token Address: ", MintTestnetLIVRContractAddress);
        console.log("Contract Staking Address: ", address(livrStakingContract));

        vm.stopBroadcast();
    }
}