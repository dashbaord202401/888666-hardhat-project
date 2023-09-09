// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

// Author: @EvilEye0666
contract Speical is Ownable, ReentrancyGuard, ERC721Enumerable {
  //toeknID => startHoldTime
  mapping(uint256 => uint256) startHoldTime;
  //days => BaseURIs
  mapping(uint256 => string) baseURIs;
  //address => Minted
  mapping(address => bool) public isPreMinted;
  uint256[] dayCount;
  bytes32 immutable root;
  //sale info
  uint256 public immutable maxTotal;
  uint256 public immutable maxMint;
  uint256 public immutable preSaleMax;
  uint256 public price;
  uint256 public mintTime;
  bool public preMintOpen;
  bool public pubMintOpen;
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
    string memory baseURI_,
    string memory name_,
    string memory symbol_,
    uint256 maxTotal_,
    uint256 maxMint_,
    uint256 preSaleMax_,
    uint256 price_,
    uint256 mintTime_,
    bytes32 merkleRoot
  ) payable ERC721(name_, symbol_) {
    baseURIs[0] = baseURI_;
    dayCount.push(0);
    maxTotal = maxTotal_;
    maxMint = maxMint_;
    preSaleMax = preSaleMax_;
    price = price_;
    mintTime = mintTime_;
    preMintOpen = !preMintOpen;
    root = merkleRoot;
  }

  function _leaf(address account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  //Premint NFT
  function preMint(
    uint256 _quantity,
    bytes32[] calldata proof
  ) external payable nonReentrant callerIsUser {
    address sender = _msgSender();
    uint256 tokenId = totalSupply();
    bool minted = isPreMinted[sender];
    require(preMintOpen && !pubMintOpen, 'PreMint close now.');
    require(
      MerkleProof.verify(proof, root, _leaf(sender)),
      'Address not in whitelist.'
    );
    require(!minted, 'Address already minted');
    require(
      tokenId + _quantity <= preSaleMax,
      'Exceed to max supply of premint.'
    );
    isPreMinted[sender] = true;
    _minNFT(sender, _quantity);
  }

  //Pubmint NFT
  function pubMint(
    uint256 _quantity
  ) external payable callerIsUser nonReentrant {
    uint256 tokenId = totalSupply();
    require(!preMintOpen && pubMintOpen, 'Public mint not open yet.');
    require(tokenId + _quantity <= maxTotal, 'Exceed to MaxSupply');
    _minNFT(_msgSender(), _quantity);
  }

  function _minNFT(address _addr, uint256 _quantity) internal {
    require(block.timestamp >= mintTime, 'Not mint time');
    require(_quantity <= maxMint, 'The Quantity Exceed to MaxMint.');
    require(price * _quantity <= msg.value, 'The value is Not Correct.');
    for (uint256 i = 0; i < _quantity; i++) {
      startHoldTime[totalSupply()] = block.timestamp;
      _safeMint(_addr, totalSupply());
    }
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
  function setBaseURI(
    uint256 _days,
    string memory _newBaseURI
  ) public onlyOwner {
    require(_days >= 1, 'setURI error.');
    bytes memory uriExist = bytes(baseURIs[_days]);
    if (uriExist.length == 0) dayCount.push(_days);
    baseURIs[_days] = _newBaseURI;
  }

  //set sale status
  function mintTarget(uint256 _status) public onlyOwner {
    require(_status == 1 || _status == 2, 'Error mintTarget');
    if (_status == 1) {
      preMintOpen = true;
      pubMintOpen = false;
    } else {
      preMintOpen = false;
      pubMintOpen = true;
    }
  }

  // *** get hold period
  function getHoldSec(uint256 _tokenid) public view returns (uint256 sec) {
    _requireMinted(_tokenid);
    uint256 nowTime = block.timestamp;
    sec = nowTime - startHoldTime[_tokenid];
  }

  // array sort
  function _insertionSort(
    uint256[] memory arr
  ) internal pure returns (uint256[] memory) {
    for (uint256 i = 1; i < arr.length; i++) {
      uint256 temp = arr[i];
      uint256 j = i;
      while ((j >= 1) && (temp < arr[j - 1])) {
        arr[j] = arr[j - 1];
        j--;
      }
      arr[j] = temp;
    }
    return (arr);
  }

  function _getURI(uint256 _tokenId) internal view returns (string memory uri) {
    uint256 holdSec = getHoldSec(_tokenId);
    uint256 oneDay = 86400;
    uint256[] memory daysArr = _insertionSort(dayCount);
    uint256 endNum = daysArr.length - 1;
    uint256 i = 1;
    while (i <= endNum) {
      if (holdSec < daysArr[i] * oneDay) {
        uri = baseURIs[daysArr[i - 1]];
        i = endNum;
      }
      i++;
    }
    if (bytes(uri).length == 0) {
      uri = baseURIs[daysArr[endNum]];
    }
  }

  //override tokenURI
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    string memory baseURI = _getURI(tokenId);
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
        : '';
  }

  //override transfers
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    startHoldTime[tokenId] = block.timestamp;
    super._transfer(from, to, tokenId);
  }

  // *** get baseURIs
  function getBaseURI(
    uint256 _days
  ) public view onlyOwner returns (string memory) {
    return baseURIs[_days];
  }

  //Withdraw ETH.
  function withdraw() public payable onlyOwner {
    uint256 amount = address(this).balance;
    Address.sendValue(payable(msg.sender), amount);
  }
}
