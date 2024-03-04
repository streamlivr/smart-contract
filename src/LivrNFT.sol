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

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";


contract LivrTickets is ERC1155, Ownable, ERC1155Pausable, ERC1155Supply {

  /////////////////////
    // State variables //
    /////////////////////
    
  string public name;
  string public symbol;

  mapping(uint => string) public s_tokenURI;


  // Have a Ticket struct that holds the token id, the maxSupply to mint and price, creator address 
  struct s_Ticket {
    uint96 tokenId;
    uint96 maxSupply;
    uint96 price;
    address creator;
  }
  
  // Have a mapping that holds the struct
  mapping(uint96 id => s_Ticket) public s_Tickets;

  /////////////////////
    // Functions       //
    /////////////////////

  constructor() ERC1155("") Ownable(msg.sender) {
    name = "Streamlivr NFTs";
    symbol = "SLN";
  }


  ////////////////////////
    // External Functions //
    ///////////////////////


  // Have a function that allows creators to add a new Ticket to the mapping
  function addTicket(uint96 _id, uint96 _maxSupply, uint96 _price) external {

    s_Ticket memory newLivrNFT = s_Ticket(_id, _maxSupply, _price, msg.sender);
    s_Tickets[_id] = newLivrNFT;
  }

  function mint(uint _id, uint _amount) external {
    
    _mint(msg.sender, _id, _amount, "");
  }

  function mintBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _mintBatch(msg.sender, _ids, _amounts, "");
  }

  function burn(uint _id, uint _amount) external {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _burnBatch(msg.sender, _ids, _amounts);
  }

  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
    _burnBatch(_from, _burnIds, _burnAmounts);
    _mintBatch(_from, _mintIds, _mintAmounts, "");
  }

  function setURI(uint _id, string memory _uri) external {
    s_tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
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