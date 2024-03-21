// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract LivrTicket is ERC1155, ReentrancyGuard, Ownable, ERC1155Pausable, ERC1155Supply {
    /////////////////////
    // Errors //
    /////////////////////
    error LivrTickets__NotAllowedToken();
    error LivrTickets__PriceTooLow();
    error LivrTickets__PriceTooHigh();
    error LivrTickets__TicketAlreadyExists();
    error LivrTickets__NotEnoughTokenBalance();
    error LivrTickets__TicketNotFound();
    error LivrTickets__TokenTransferFailed();

    /////////////////////
    // State variables //
    /////////////////////

    string public name;
    string public symbol;
    address public immutable i_tokenAddress;

    mapping(uint256 => string) public s_tokenURI;

    // Have a Ticket struct that holds the token id, the maxSupply to mint and price, creator address
    struct s_Ticket {
        uint96 tokenId;
        uint96 maxSupply;
        uint256 price;
        address creator;
        string uri;
    }

    // Have a mapping that holds the struct
    mapping(uint96 id => s_Ticket) public s_Tickets;

    /////////////////////
    // Events        ///
    ////////////////////

    event TicketCreated(uint96 indexed tokenId, uint96 maxSupply, uint256 price, address indexed creator, string uri);

    event PurchasedTicket(
        address indexed buyer, address indexed creator, uint96 indexed tokenId, uint256 numTickets, uint256 price
    );

    /////////////////////
    // Modifiers      ///
    /////////////////////

    modifier NotAllowedToken(address token) {
        if (token != address(i_tokenAddress)) {
            revert LivrTickets__NotAllowedToken();
        }
        _;
    }

    modifier PriceCheck(uint256 amount) {
        if (amount < 5 * 10 ** 18) {
            revert LivrTickets__PriceTooLow();
        } else if (amount > 500 * 10 ** 18) {
            revert LivrTickets__PriceTooHigh();
        }
        _;
    }

    /////////////////////
    // Functions       //
    /////////////////////

    constructor(address _tokenAddress) ERC1155("") Ownable(msg.sender) {
        name = "Streamlivr NFTs";
        symbol = "STRN";
        i_tokenAddress = _tokenAddress;
    }

    ////////////////////////
    // External Functions //
    ///////////////////////

    // Have a function that allows creators to add a new Ticket to the mapping
    function createTicket(uint96 _id, uint96 _maxSupply, uint256 _price, string memory _uri)
        external
        nonReentrant
        PriceCheck(_price)
    {
        // Use an if statement to check if the tokenId already exists in the mapping and revert with custom error message if it does
        if (s_Tickets[_id].tokenId != 0) {
            revert LivrTickets__TicketAlreadyExists();
        }

        s_Ticket memory newLivrNFT = s_Ticket(_id, _maxSupply, _price, msg.sender, _uri);
        s_Tickets[_id] = newLivrNFT;

        // Call setURI function to set the URI for the token
        setURI(_id, _uri);
        emit TicketCreated(_id, _maxSupply, _price, msg.sender, _uri);
    }

    function mint(uint96 _id, uint256 numTickets) external payable {
        // find the ticket in the mapping
        s_Ticket memory ticket = s_Tickets[_id];
        // Calcuate cost for ticket numTickets * ticket price
        uint256 cost = ticket.price * numTickets;
        // Check if the user has enough balance to mint the tickets
        if (IERC20(i_tokenAddress).balanceOf(msg.sender) < cost) {
            revert LivrTickets__NotEnoughTokenBalance();
        }
        // Calculate the 5% fee and the remaining amount to send to the creator
        uint256 fee = cost * 5 / 100;
        uint256 creatorAmount = cost - fee;

        // Transfer the tokens from the user to the contract and the creator
        IERC20 token = IERC20(i_tokenAddress);
        bool sentPercentage = token.transferFrom(msg.sender, address(this), fee);
        bool sentCreator = token.transferFrom(msg.sender, ticket.creator, creatorAmount);

        if (!sentPercentage || !sentCreator) {
            revert LivrTickets__TokenTransferFailed();
        }

        _mint(msg.sender, _id, numTickets, "");

        emit PurchasedTicket(msg.sender, ticket.creator, _id, numTickets, cost);
    }

    function mintBatch(uint256[] memory _ids, uint256[] memory _amounts) external {
        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts) external {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function setURI(uint256 _id, string memory _uri) public {
        s_tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return s_tokenURI[_id];
    }

    function changeOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

    ////////////////////////
    // Internal Functions //
    ///////////////////////

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
