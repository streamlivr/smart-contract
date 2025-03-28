// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC7802, IERC165} from "@interop-lib/interfaces/IERC7802.sol";

contract LivrSuper is ERC20, Ownable, IERC7802 {
  error LivrToken_MustBeMoreThanZero();
  error LivrToken_NotZeroAddress();
  error LivrToken_NotAuthorized();

  constructor(address _owner, uint256 initialSupply) ERC20("Streamlivr", "LIVR") Ownable(_owner)  {
    _mint(_owner, initialSupply);
  }

  function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
    if (_to == address(0)) {
        revert LivrToken_NotZeroAddress();
    }

    if (_amount <= 0) {
        revert LivrToken_MustBeMoreThanZero();
    }

    _mint(_to, _amount);
    return true;
  }

  function crosschainMint(address _to, uint256 _amount) external {
    if (msg.sender != PredeployAddresses.SUPERCHAIN_TOKEN_BRIDGE  || msg.sender != owner()) {
      revert LivrToken_NotAuthorized();
    }

    _mint(_to, _amount);

    emit CrosschainMint(_to, _amount, msg.sender);
  }

  /// @notice Allows the SuperchainTokenBridge to burn tokens.
  /// @param _from   Address to burn tokens from.
  /// @param _amount Amount of tokens to burn.
  function crosschainBurn(address _from, uint256 _amount) external {
    if (msg.sender != PredeployAddresses.SUPERCHAIN_TOKEN_BRIDGE  || msg.sender != owner()) {
      revert LivrToken_NotAuthorized();
    }
    // require(msg.sender == PredeployAddresses.SUPERCHAIN_TOKEN_BRIDGE, "Unauthorized");

    _burn(_from, _amount);

    emit CrosschainBurn(_from, _amount, msg.sender);
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual returns (bool) {
    return _interfaceId == type(IERC7802).interfaceId || _interfaceId == type(IERC20).interfaceId
        || _interfaceId == type(IERC165).interfaceId;
  }
}