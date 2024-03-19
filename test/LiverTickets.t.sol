pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/LivrTickets.sol";
import "../src/LivrToken.sol";

contract LiverTicketTest is Test {
    LivrToken public livrToken;
    LivrTicket public livrTicket;

    function setUp() public {
        livrToken = new LivrToken(1000000000 * 10 ** 18);
        livrTicket = new LivrTicket(address(livrToken));
    }
}
