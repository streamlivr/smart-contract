# Streamlivr smart contracts
This code base consists of 5 contracts: LivrNft, LivrTicket, LivrSale, LivrToken, Staking.sol

## LivrToken.sol
Is our Livr Token contract which is an [ERC20](https://eips.ethereum.org/EIPS/eip-20) and has functions of one.

## LivrNft
This contract is an [ERC1155](https://eips.ethereum.org/EIPS/eip-1155) nft contract.
The Nft standard used is the ERC1155 nft standard to manage total supply of nfts and tokens.
### Variable
- name: Livr Nft
- symbol: LN
- s_tokenURI: is a maaping that stores uri for every token

### Functions
- mint: mint funtion.
  <u>Params</u>
  - address _to: the address the nft would be mint to
  - uint256 _id: id of the token
  - uint256 _amount: total supply of the nft
- mintBatch: mint more than one.
  <u>Params</u>
    - address _to: address the nft would be mint to
    - uint256[] _id: array of ids for the token
    - uint256[] _amount: array of total supply of the tokenId
- burn: burn a token
  <u>Params</u>
    - uint256 _id: id of the token
    - uint256 _amount: total supply of the nft
- burnBatch: burn more than one token.
  <u>Params</u>
    - uint256[] _id: id of the token
    - uint256[] _amount: total supply of the nft
- setURI: set token uri.
  <u>Params</u>
    - uint256 _id: id of the token
    - string _uri: url for the nft
- changeOwner: change owner of contract.
  <u>Params</u>
      - address newOwner: address of the new owner.
- uri: gets the uri of the tokenId passed to it.
  <u>Params</u>
      - uint256 _id_: id of token.




# Staking Periods and reward percentage
- 30 days 1.5%
- 1yr 5%
- 2yrs 10%

# Swapping
Staked assets to be added to the pool
 - Toro NGN
 - USDT
 - WBTC
