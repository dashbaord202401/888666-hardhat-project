// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// Github: @Evileye0666
contract Skulls is ERC721Enumerable, Ownable, ReentrancyGuard {
  uint256 public immutable maxTotal;
  uint256 public immutable maxMint;
  uint256 public immutable price;
  string baseURI;
  address withdrawAddr;
  //Error
  error Allowed_Only_User();
  error Exceed_To_MaxSupply(uint256 MaxSupply_, uint256 YourMint_);
  error Exceed_To_MaxMint(uint256 MaxMint_, uint256 YourMint_);
  error Value_Not_Right(uint256 AllPrice_, uint256 YourValue_);
  error Not_Set_withdraw(address NowAddress_);
  //only user
  modifier callerIsUser() {
    if (tx.origin != _msgSender()) {
      revert Allowed_Only_User();
    }
    _;
  }

  //start
  constructor(
    string memory _ipfsURI,
    string memory _name,
    string memory _symbol,
    uint256 _maxTotal,
    uint256 _maxMint,
    uint256 _price,
    address _withdrawAddr
  ) payable ERC721(_name, _symbol) {
    baseURI = _ipfsURI;
    maxTotal = _maxTotal;
    maxMint = _maxMint;
    price = _price;
    withdrawAddr = _withdrawAddr;
  }

  //Pubmint NFT
  function pubMint(
    uint256 _quantity
  ) external payable callerIsUser nonReentrant {
    uint256 tokenId = totalSupply();
    uint256 maxSupply = maxTotal;
    if (tokenId + _quantity > maxSupply) {
      revert Exceed_To_MaxSupply({
        MaxSupply_: maxSupply,
        YourMint_: tokenId + _quantity
      });
    }
    uint256 mintMax = maxMint;
    if (_quantity > mintMax) {
      revert Exceed_To_MaxMint({ MaxMint_: mintMax, YourMint_: _quantity });
    }
    uint256 totalPrice = price * _quantity;
    if (totalPrice > msg.value) {
      revert Value_Not_Right({ AllPrice_: totalPrice, YourValue_: msg.value });
    }
    address minter = _msgSender();
    for (uint256 i = 1; i <= _quantity; i++) {
      _safeMint(minter, tokenId + i);
    }
  }

  //set withdrawAddr
  function setwithdrawAddr(address _withdrawAddr) public onlyOwner {
    withdrawAddr = _withdrawAddr;
  }

  //set token url
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  //Get Withdraw Address.
  function getwithdrawAddr() public view onlyOwner returns (address) {
    return withdrawAddr;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //Withdraw ETH.
  function withdraw() public payable onlyOwner {
    if (withdrawAddr == address(0)) {
      revert Not_Set_withdraw({ NowAddress_: withdrawAddr });
    }
    uint256 amount = address(this).balance;
    Address.sendValue(payable(withdrawAddr), amount);
  }
}
