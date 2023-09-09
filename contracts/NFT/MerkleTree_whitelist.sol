// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

// Author: @EvilEye0666
contract Project is ERC721Enumerable, Ownable, ReentrancyGuard {
  mapping(address => bool) public isMinted;
  bytes32 public immutable root;
  //sale info
  uint256 public immutable maxSuppply;
  uint256 public immutable preSaleMax;
  uint256 public immutable preSaleMaxMint;
  uint256 public price;
  uint256 public mintTime;
  bool public preMintOpen;
  bool public pubMintOpen;
  string baseURI;
  //only user
  modifier callerIsUser() {
    require(
      !Address.isContract(_msgSender()),
      "You can't minting from Contract"
    );
    _;
  }

  //start
  constructor(
    string memory _metaURI,
    string memory _name,
    string memory _symbol,
    uint256 _maxSuppply,
    uint256 _preSaleMax,
    uint256 _preSaleMaxMint,
    uint256 _price,
    uint256 _mintTime,
    bytes32 _merkleRoot
  ) payable ERC721(_name, _symbol) {
    baseURI = _metaURI;
    maxSuppply = _maxSuppply;
    preSaleMax = _preSaleMax;
    preSaleMaxMint = _preSaleMaxMint;
    price = _price;
    mintTime = _mintTime;
    preMintOpen = !preMintOpen;
    root = _merkleRoot;
  }

  //Premint NFT
  function preMint(
    uint256 _quantity,
    bytes32[] calldata proof
  ) external payable nonReentrant callerIsUser {
    address sender = _msgSender();
    bool minted = isMinted[sender];
    require(preMintOpen, 'Premint close now.');
    require(
      MerkleProof.verify(proof, root, _leaf(sender)),
      'The address not in whitelist.'
    );
    require(!minted, 'The address have been minted');
    require(_quantity <= preSaleMaxMint, 'Exceed to preSaleMaxMint.');
    require(totalSupply() + _quantity <= preSaleMax, 'Exceed to preSaleMax.');
    isMinted[sender] = true;
    _minNFT(sender, _quantity);
  }

  //Pubmint NFT
  function pubMint(
    uint256 _quantity
  ) external payable callerIsUser nonReentrant {
    require(pubMintOpen, 'Public mint not open yet.');
    require(totalSupply() + _quantity <= maxSuppply, 'Exceed to MaxSupply');
    _minNFT(_msgSender(), _quantity);
  }

  function _minNFT(address _addr, uint256 _quantity) internal {
    uint256 tokenId = totalSupply();
    require(block.timestamp >= mintTime, 'Too early to mint.');
    require(price * _quantity <= msg.value, 'The value is not correct.');
    for (uint256 i = 0; i < _quantity; i++) {
      _safeMint(_addr, tokenId + i);
    }
  }

  function _leaf(address account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  //Mint Time
  function setMintTime(uint256 _mintTime) public onlyOwner {
    mintTime = _mintTime;
  }

  //Mint Price(ETH)
  function setMintPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  //set token url
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  //set pre sale status
  function preMintTarget() public onlyOwner {
    preMintOpen = !preMintOpen;
  }

  //set pub sale status
  function pubMintTarget() public onlyOwner {
    pubMintOpen = !pubMintOpen;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //Withdraw ETH.
  function withdraw() public payable onlyOwner {
    uint256 amount = address(this).balance;
    Address.sendValue(payable(_msgSender()), amount);
  }
}
