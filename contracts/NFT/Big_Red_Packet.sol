// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Big_Red_Packet is ERC721Enumerable, Ownable {
  uint256 private constant MAX_SUPPLY = 10000;
  uint256 private constant PRICE = 80000000000000000;
  uint256 private constant BONUS_OF_SETLIST = 5000000000000000000;
  uint256 private immutable TIME_OF_SETLIST;
  uint256 private immutable MINIMUN_SUPPLY;
  uint256 private immutable NONCE;
  string private IMG_URL;
  uint256[] private LUCKY_NUMBER;
  uint256 private openCount;
  struct BonusInfo {
    uint256 bonusNumber;
    bool isOpened;
  }
  mapping(uint256 tokenId => BonusInfo) tokenInfo;
  uint256[] private bonuses = [
    0,
    10000000000000000,
    20000000000000000,
    50000000000000000,
    80000000000000000,
    200000000000000000,
    500000000000000000,
    2000000000000000000,
    5000000000000000000,
    10000000000000000000,
    20000000000000000000,
    50000000000000000000
  ];
  uint256[] private amounts = [
    5000,
    2000,
    1000,
    1000,
    569,
    200,
    200,
    15,
    10,
    3,
    2,
    1
  ];

  event openPackets(
    uint256 indexed allBonus,
    uint256[] tokenIds,
    uint256[] bonuses
  );
  error callFaild(uint256 amount, uint256[] number);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _imgUrl,
    uint256[] memory _luckyNumber,
    uint256 _timeOfSetList,
    uint256 _minSupply,
    uint256 _nonce
  ) payable ERC721(_name, _symbol) {
    IMG_URL = _imgUrl;
    LUCKY_NUMBER = _luckyNumber;
    TIME_OF_SETLIST = _timeOfSetList;
    MINIMUN_SUPPLY = _minSupply;
    NONCE = _nonce;
  }

  function mintRedPackets(address _to, uint256 _quantity) external payable {
    uint256 tokenId = totalSupply();
    require(
      tokenId + _quantity <= MAX_SUPPLY && PRICE * _quantity <= msg.value
    );
    for (uint256 i = 0; i < _quantity; i++) {
      _safeMint(_to, tokenId + i);
    }
  }

  function openRedPackets(uint256 _quantity) external payable {
    uint256[] memory luckyNumber_ = LUCKY_NUMBER;
    require(
      totalSupply() >= luckyNumber_[6] && block.timestamp >= luckyNumber_[7]
    );
    address opener = msg.sender;
    require(tx.origin == opener && _quantity < 11 && _quantity > 0);
    require(getUnOpenedCount(opener) >= _quantity);
    uint256[] memory tokenIds_ = _getOpeningIds(opener, _quantity);
    uint256[] memory tempBonuses = bonuses;
    uint256[] memory tempAmounts = amounts;
    uint256[] memory tempIdToBonus = new uint256[](tokenIds_.length);
    uint256 tempAllBonus;
    uint256 tempCount = openCount;
    unchecked {
      for (uint256 i = 0; i < _quantity; i++) {
        tempCount++;
        uint256 x = _checkIsWinner(tempCount, luckyNumber_);
        uint256 bonusIndex = x == 88
          ? _getRandomIndex(tempAmounts, tempCount)
          : x;
        tempIdToBonus[i] = tempBonuses[bonusIndex];
        tempAllBonus += tempIdToBonus[i];
        tokenInfo[tokenIds_[i]] = BonusInfo(bonusIndex, true);
        tempAmounts[bonusIndex]--;
      }
      openCount = tempCount;
      amounts = tempAmounts;
    }
    if (tempAllBonus > 0) {
      (bool success, ) = payable(opener).call{ value: tempAllBonus }('');
      if (!success) {
        revert callFaild(tempAllBonus, tempIdToBonus);
      }
    }
    emit openPackets(tempAllBonus, tokenIds_, tempIdToBonus);
  }

  function _checkIsWinner(
    uint256 _count,
    uint256[] memory _luckNumber
  ) private pure returns (uint256 x_) {
    unchecked {
      if (_count == _luckNumber[0]) {
        x_ = 11;
      } else if (_count == _luckNumber[1] || _count == _luckNumber[2]) {
        x_ = 10;
      } else if (
        _count == _luckNumber[3] ||
        _count == _luckNumber[4] ||
        _count == _luckNumber[5]
      ) {
        x_ = 9;
      } else {
        x_ = 88;
      }
    }
  }

  function _getRandomIndex(
    uint256[] memory _amounts,
    uint256 _tempCount
  ) private view returns (uint256 index_) {
    uint256 index = uint256(
      keccak256(
        abi.encodePacked(
          _tempCount,
          msg.sender,
          block.prevrandao,
          block.number,
          block.timestamp
        )
      )
    ) % (_amounts.length - 3);
    index_ = _amounts[index] > 0 ? index : _randomLoop(_amounts, index);
  }

  function _randomLoop(
    uint256[] memory _amounts,
    uint256 _index
  ) private pure returns (uint256 index_) {
    unchecked {
      index_ = _index;
      while (index_ > 0) {
        index_--;
        if (_amounts[index_] > 0) {
          return index_;
        }
      }
      index_ = _index;
      while (index_ < _amounts.length - 4) {
        index_++;
        if (_amounts[index_] > 0) {
          return index_;
        }
      }
    }
  }

  function getBonusInfo(
    uint256 _tokenId
  ) public view returns (BonusInfo memory) {
    return tokenInfo[_tokenId];
  }

  function _getUnOpenedId(
    address owner
  ) private view returns (uint256[] memory) {
    uint256 x = ERC721.balanceOf(owner);
    uint256 count = 0;

    unchecked {
      for (uint256 i = 0; i < x; i++) {
        uint256 z = tokenOfOwnerByIndex(owner, i);
        if (!getBonusInfo(z).isOpened) count++;
      }
      uint256[] memory y = new uint256[](count);
      for (uint256 i = 0; i < x; i++) {
        uint256 z = tokenOfOwnerByIndex(owner, i);
        if (!getBonusInfo(z).isOpened) y[i] = z;
      }
      return y;
    }
  }

  function getUnOpenedCount(address owner) public view returns (uint256 x) {
    x = _getUnOpenedId(owner).length;
  }

  function _getOpeningIds(
    address owner,
    uint256 count
  ) private view returns (uint256[] memory) {
    uint256[] memory tempList = _getUnOpenedId(owner);
    uint256[] memory x = new uint256[](count);
    unchecked {
      for (uint256 i = 0; i < count; i++) {
        x[i] = tempList[i];
      }
      return x;
    }
  }

  function getAmounts() external view returns (uint256[] memory) {
    return amounts;
  }

  function getOpenCount() external view returns (uint256) {
    return openCount;
  }

  function _getURI(uint256 _id) private view returns (string memory uri) {
    uint256 x = tokenInfo[_id].isOpened
      ? tokenInfo[_id].bonusNumber
      : bonuses.length;
    uri = string.concat(IMG_URL, string.concat(Strings.toString(x), '/'));
  }

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

  function _getLeftOverBonus() private view returns (uint256 totalBonus) {
    uint256[] memory bonuses_ = bonuses;
    uint256[] memory amounts_ = amounts;
    for (uint256 i = 1; i < bonuses_.length; i++) {
      totalBonus += bonuses_[i] * amounts_[i];
    }
  }

  function withdraw() external payable onlyOwner {
    uint256 allBalance = address(this).balance;
    uint256 leftOver = _getLeftOverBonus();
    require(allBalance > leftOver);
    uint256 amount = openCount == MAX_SUPPLY
      ? allBalance
      : allBalance - leftOver;
    payable(msg.sender).call{ value: amount };
  }
}
