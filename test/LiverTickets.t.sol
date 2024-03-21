// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/LivrTickets.sol";
import "../src/LivrToken.sol";

contract LiverTicketTest is Test {
    LivrToken public livrToken;
    LivrTicket public livrTicket;

    function setUp() public {
        livrToken = new LivrToken(100 * 10 ** 18, address(1));
        livrTicket = new LivrTicket(address(livrToken));
    }

    function testCreateTicket() public {
        livrTicket.createTicket(1, 100, 5000000000000000000, "https://www.google.com");
        string memory tokenURI = livrTicket.s_tokenURI(1);
        assertEq(tokenURI, "https://www.google.com");
    }
}
