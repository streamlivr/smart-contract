// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/LivrTickets.sol";
import "../src/LivrToken.sol";

contract LiverTicketTest is Test {
    LivrToken public livrToken;
    LivrTicket public livrTicket;

    function setUp() public {
        livrToken = new LivrToken(100 * 10 ** 18, address(this));
        livrTicket = new LivrTicket(address(livrToken));
    }

    function testCreateTicket() public {
        livrTicket.createTicket(100, 5000000000000000000, "https://www.google.com");
        livrTicket.createTicket(100, 5000000000000000000, "https://www.google.com");
        string memory tokenURI = livrTicket.s_tokenURI(1);
        uint96 counter = livrTicket.s_tokenIdCounter();
        assertEq(tokenURI, "https://www.google.com");
        assertEq(counter, 2);
    }

    // function testMintTicket() public {
    //     livrTicket.createTicket(100, 5000000000000000000, "https://www.google.com");
    //     livrToken.
    //     livrTicket.mint(1, 10);
    //     uint256 balance = livrTicket.balanceOf(address(this), 1);
    //     assertEq(balance, 10);
    // }
}
