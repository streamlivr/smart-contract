// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../src/LivrSale.sol";

contract LivrSaleScript is Script {
    function setUp() public {}

    function run() public {
      
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);

        console.log("Account", account);

        vm.startBroadcast(privateKey);



        new LivrSale(0x5fd84259d66Cd46123540766Be93DFE6D43130D7, 0xEe0203F4C79634d40136F8481Bdc1edf1D1325E8);

        vm.stopBroadcast();
    }
}

