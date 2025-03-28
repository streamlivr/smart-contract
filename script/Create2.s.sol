// SPDX-License-Identifier: MIT 
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import "../src/SuperErc20.sol";

contract DeploySuper is Script {
  event log(address value);
  event logByte(bytes value);
  event Deployed(address addr, string salt);

  function setUp() public {}

  function run () external{
    vm.startBroadcast();

    bytes memory initCode = abi.encodePacked(
      type(LivrSuper).creationCode, abi.encode(0x68E6971E91851C24011b7FaD98D38541D90Be0a9, 500000000000000000000000000)
    );

    emit logByte(initCode);

    address preComputedAddress = vm.computeCreate2Address(_implSalt(), keccak256(initCode));

    // Check address
    // address expectedAddress = factory.getAddress(bytecode, 200);
    emit log(preComputedAddress);

    address addr;
    addr = address(new LivrSuper{salt: _implSalt()}(0x68E6971E91851C24011b7FaD98D38541D90Be0a9, 500000000000000000000000000));
    // assembly {
    //   addr :=
    //     create2(
    //       callvalue(), // wei sent with current call
    //       // Actual code starts after skipping the first 32 bytes
    //       add(bytecode, 0x20),
    //       mload(bytecode), // Load the size of code contained in the first 32 bytes
    //       "777" // Salt from function arguments
    //     )

    //   if iszero(extcodesize(addr)) { revert(0, 0) }
    // }

    // emit Deployed(addr, "777");
    

    vm.stopBroadcast();  
  }

  function _implSalt() internal view returns (bytes32) {
        string memory salt = "777";
        return keccak256(abi.encodePacked(salt));
    }
}

