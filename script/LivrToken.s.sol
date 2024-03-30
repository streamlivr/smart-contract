// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../src/LivrToken.sol";

contract LivrTokenScript is Script {
    function setUp() public {}

    function run() public {
        // Deploy LivrToken
        // deploy("LivrToken", 100 * 10 ** 18, address(this));
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);

        console.log("Account", account);

        vm.startBroadcast(privateKey);

        LivrToken livrToken = new LivrToken(100 * 10 ** 18, account);

        livrToken.MAX_SUPPLY();

        vm.stopBroadcast();
    }
}
