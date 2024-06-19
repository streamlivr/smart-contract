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
    //////////////
    // Errors //
    /////////////
    error LivrTickets__NotAllowedToken();
    error LivrTickets__PriceTooLow();
    error LivrTickets__PriceTooHigh();
    error LivrTickets__TicketAlreadyExists();
    error LivrTickets__NotEnoughTokenBalance();
    error LivrTickets__TicketNotFound();
    error LivrTickets__TokenTransferFailed();
    error LivrTickets__TicketSoldOut();
    error LivrTickets__NotEnoughTickets();

    /////////////////////
    // State variables //
    /////////////////////

    string public name;
    string public symbol;
    address public immutable i_tokenAddress;
    uint96 public s_tokenIdCounter = 0;
    uint96 public s_SoldOutTickets = 0;

    mapping(uint256 => string) public s_tokenURI;

    // Have a Ticket struct that holds the token id, the maxSupply to mint and price, creator address
    struct s_Ticket {
        uint96 tokenId;
        uint96 supply;
        uint96 maxSupply;
        uint256 price;
        address creator;
        string uri;
    }

    // struct

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
    function createTicket(uint96 _maxSupply, uint256 _price, string memory _uri)
        external
        nonReentrant
        PriceCheck(_price)
    {
        uint96 _tokenId = s_tokenIdCounter + 1;
        s_Ticket memory newLivrNFT = s_Ticket(_tokenId, _maxSupply, _maxSupply, _price, msg.sender, _uri);
        s_Tickets[_tokenId] = newLivrNFT;
        s_tokenIdCounter = _tokenId;

        // Call setURI function to set the URI for the token
        setURI(_tokenId, _uri);
        emit TicketCreated(_tokenId, _maxSupply, _price, msg.sender, _uri);
    }

    function mint(uint96 _id, uint96 numTickets) external payable nonReentrant {
        // find the ticket in the mapping
        s_Ticket memory ticket = s_Tickets[_id];
        // Check if supply is greater or equal to the number of tickets to mint

        if (ticket.supply == 0) {
            revert LivrTickets__TicketSoldOut();
        }

        if (ticket.supply < numTickets) {
            revert LivrTickets__NotEnoughTickets();
        }
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
        bool payContract = token.transferFrom(msg.sender, address(this), cost);
        bool payCreator = token.transferFrom(address(this), ticket.creator, creatorAmount);

        if (!payContract || !payCreator) {
            revert LivrTickets__TokenTransferFailed();
        }

        s_Tickets[_id].supply -= numTickets;

        _mint(msg.sender, _id, numTickets, "");

        uint96 supply = ticket.supply - numTickets;
        if (supply == 0) {
            s_SoldOutTickets += 1;
        }

        emit PurchasedTicket(msg.sender, ticket.creator, _id, numTickets, cost);
    }

    // SaleMyNft

    function fetchTickets() external view returns (s_Ticket[] memory) {
        // return all the tickets in the mapping
        uint96 itemCount = s_tokenIdCounter;
        uint256 unsoldItemCount = s_tokenIdCounter - s_SoldOutTickets;
        uint256 currentIndex = 0;

        s_Ticket[] memory items = new s_Ticket[](unsoldItemCount);
        for (uint96 i = 0; i < itemCount; i++) {
            if (s_Tickets[i + 1].supply > 0) {
                uint96 currentId = i + 1;
                s_Ticket memory currentItem = s_Tickets[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // function mintBatch(uint256[] memory _ids, uint256[] memory _amounts) external {
    //     _mintBatch(msg.sender, _ids, _amounts, "");
    // }

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

    function setURI(uint256 _id, string memory _uri) public onlyOwner {
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
