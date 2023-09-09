// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is ERC721Enumerable, Ownable {
	using Strings for uint256;
	error turnOnFail();
	error withdrawFail();
	uint256 private immutable LOTTERY_ID;
	uint256 private constant MAX_SUPPLY = 10000 ;
	uint256 private constant PRICE = 100000000000000000;
	uint256 private constant BONUS_OF_SETLIST = 5 ether;
	uint256 private constant BONUS_OF_TOPHOLDER = 20 ether;
	uint256[][] private LUCKY_COUNTS;
	uint256[] private LUCKY_INDEXS;
	uint256[] private LUCKY_NUMBERS;
	uint256[] private bonuses = [
		0,5 ether,12 ether,20 ether,25 ether,50 ether
	];
	uint256[] private amounts = [0, 10, 4, 3, 2, 1];
	uint256 private timeToOn;
	string private TOKEN_URL;
	address private lotteryOpener;
	address private topHoldWinner;
	mapping(uint256 => bool) private isWithdraw;

	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _openTime,
		string memory _token_url,
		uint256[][] memory _luckyCounts,
		uint256[] memory _luckyIndexs,
		uint256 _lotteryId
	) payable ERC721(_name, _symbol) {
		timeToOn = _openTime;
		TOKEN_URL = _token_url;
		LUCKY_COUNTS = _luckyCounts;
		LUCKY_INDEXS = _luckyIndexs;
		LOTTERY_ID = _lotteryId;
	}

	function mint(address _to, uint256 _quantity) external payable {
		require(_quantity > 0);
		require(PRICE * _quantity <= msg.value);
		uint256 tokenId = totalSupply();
		require(tokenId + _quantity < MAX_SUPPLY);
		for (uint256 i = 0; i < _quantity; i++) {
			_safeMint(_to, tokenId + i);
		}
	}

	function turnOn(address _opener,address _topHolder,uint256 _lotteryId) external {
		require(ERC721.balanceOf(_opener) > 0);
		require(_lotteryId == LOTTERY_ID);
		require(block.timestamp >= timeToOn);
		require(lotteryOpener == address(0));
		uint256[][] memory luckyCounts_ = LUCKY_COUNTS;
		uint256 luckyNum = uint256(
			keccak256(abi.encodePacked(_opener,block.timestamp,block.prevrandao))
		) % (luckyCounts_.length);
		LUCKY_NUMBERS = luckyCounts_[luckyNum];
		lotteryOpener = _opener;
		topHoldWinner = _topHolder;
		uint256 turnOnId = MAX_SUPPLY;
		isWithdraw[turnOnId] =true;
		_safeMint(_opener, turnOnId);
		(bool success, ) = payable(_opener).call{value: BONUS_OF_SETLIST}("");
		if (!success) {
			revert turnOnFail();
		}
	}

	function withdrawPrize(address _opener, uint256[] calldata tokenIds) external {
		require(lotteryOpener != address(0));
		require(ERC721.balanceOf(_opener) > 0);
		uint256[] memory tempBonuses_ = bonuses;
		uint256[] memory tempAmounts_ = getAmounts();
		uint256 tempAllBonus_;
		unchecked {
			for (uint256 i = 0; i < tokenIds.length; i++) {
				require(ERC721.ownerOf(tokenIds[i]) == _opener);
				require(isWithdraw[tokenIds[i]] == false);
				uint256 prizeIdx = _getLuckyNumber(tokenIds[i]);
				require(prizeIdx > 0);
				tempAmounts_[prizeIdx]--;
				tempAllBonus_ += tempBonuses_[prizeIdx];
				isWithdraw[tokenIds[i]] = true;
			}
			amounts = tempAmounts_;
		}
		(bool success, ) = payable(_opener).call{value: tempAllBonus_}("");
		if (!success) revert withdrawFail();
	}

	function withdrawTopWinPrize(address _topHolder) external {
		require(topHoldWinner == _topHolder);
		uint256 turnOnId = MAX_SUPPLY+1;
		isWithdraw[turnOnId] =true;
		_safeMint(_topHolder, turnOnId);		
		(bool success, ) = payable(_topHolder).call{value: BONUS_OF_TOPHOLDER}("");
		if (!success) revert withdrawFail();	
	}

	function setTime(uint256 _time) external onlyOwner {
		timeToOn = _time;
	}

	function withdraw() external payable onlyOwner {
		uint256[] memory bonuses_ = bonuses;
		uint256[] memory amounts_ = getAmounts();
		uint256 totalBonus;
		for (uint256 i = 1; i < bonuses_.length; i++) {
			totalBonus += bonuses_[i] * amounts_[i];
		}
		uint256 allBalance = address(this).balance;
		require(allBalance > totalBonus);
		uint256 price = allBalance - totalBonus;
		payable(msg.sender).call{value: price};
	}

	function getAmounts() public view returns (uint256[] memory) {
		return amounts;
	}
	function getLotteryOpener() external view returns (address) {
		return lotteryOpener;
	}

	function getTopHolder() external view returns (address) {
		return topHoldWinner;
	}

	function _baseURI() internal view override returns (string memory) {
    return TOKEN_URL;
  }

	function getUnWithdrawWinIds(address _owner) external view returns (uint256[] memory) {
		uint256[] memory luckyNumbrs_ = LUCKY_NUMBERS;
		uint256 x = ERC721.balanceOf(_owner);
		uint256[] memory ids;
		unchecked {
			for (uint256 i = 0; i < x; i++) {
				uint256 z = tokenOfOwnerByIndex(_owner, i);
				for (uint256 j = 0; j < luckyNumbrs_.length; j++) {
					if (z == luckyNumbrs_[j] && !isWithdraw[z]) ids[i] = z;
				}
			}
			return ids;
		}
	}

	function _getLuckyNumber(uint256 _tokenId) private view returns (uint256) {
		uint256[] memory luckyNumbers_ = LUCKY_NUMBERS;
		uint256[] memory luckyIndexs_ = LUCKY_INDEXS;		
		unchecked {
			uint256 x;
			for (uint256 i = 0; i < luckyNumbers_.length; i++) {
				if (luckyNumbers_[i] == _tokenId) return luckyIndexs_[i];
			}
			return x;
		}
	}
}
