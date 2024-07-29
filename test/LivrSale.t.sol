// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./mock/Token.sol";
import "../src/LivrSale.sol";

contract SaleTest is Test {
  LivrSale livrSale;
  Token token;
  Token usdc;

  


  function setUp() public {
    // Deploy token contracts
    token = new Token(100000000000000000000000000000, "TstreamLivr", "TLIVR");
    usdc = new Token(100000000000000000000000000000, "Dollar", "USDC");
    // Deploy Presale contract
    livrSale = new LivrSale(address(usdc), address(token));

    // Allow livrSale to tranfer usdc
    usdc.approve(address(livrSale), 1000000000000000000000000000);

    // Transfer livr to sale contract
    token.transfer(address(livrSale), 1000000000000000000000000000);
  }

  function testFail_balance() public {
    uint256 bal = token.balanceOf(address(this));
    assertEq(100000000000000000000000000000, bal);
  }

  function test_allowance () public {
    uint256 allowance = usdc.allowance(address(this), address(livrSale));
    assertEq(1000000000000000000000000000, allowance);
  }

  function test_calcuateLivr() public {
    uint256 result =  livrSale.calculateSale(10000000000000000000);
    assertEq(1162790000000000000000, result);
  }



  function test_buy() public {
    uint256 amount = 10000000000000000000;

    // First check livr balance 
    uint256 preBalance = token.balanceOf(address(this));
    uint256 uPrebalance =  usdc.balanceOf(address(this));
    uint256 result =  livrSale.calculateSale(amount);
    livrSale.buy(amount);
    uint256 postBalance = token.balanceOf(address(this));
    uint256 uPostbalance = usdc.balanceOf(address(this));
    uint256 usdBalance = uPrebalance - amount;
    assertEq(uPrebalance, usdBalance);
  }
  // function test_buy
}