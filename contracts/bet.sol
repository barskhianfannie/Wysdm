pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./bank.sol";
import "hardhat/console.sol";

contract PriceBets{

struct Bet {
    string assetNname;
    address adrs;
    uint amount;
    uint betEndTime;
    Price priceBet;
}

event NewBet(
  address adrs, 
  uint amount, 
  Price priceBet
);


struct Price{
    string assetName;
    uint price;
    bool greaterThan;
    uint totalBetAmount;
}

Bet[] public bets;
Price[] public prices;
    
address payable betContractOwner;
uint public totalMoneyOnBet = 0;

mapping (address => uint) public numberOfBetsPerAddress;

event BetEnded(bool wasPriceGreaterThan);

constructor(string _assetName, uint _price, uint bettingTime) payable {
    betContractOwner = payable(msg.sender); // setting the contract creator - this person cannot bet
    prices.push(Price(_assetName, _price, true, 0)); // the first index will be for bets that it will be greater than
    prices.push(Price(_assetName, _price, false, 0)); // the second index will be for bets that it will be less than 
    betEndTime = block.timestamp + bettingTime;
}

function createPrice(string memory _assetName, uint memory _price, bool memory _greaterThan) public {
    prices.push(Price(_assetName, _price, _greaterThan, 0));
}

function getTotalBetAmount (uint _priceId) public view returns (uint) {
    return prices[_priceId].totalBetAmount;
}


function createBet (string memory _assetName, uint _priceId) external payable {       
    require (msg.sender != betContractOwner, "Sorry, the owner can't make a bet");
    require (numBetsAddress[msg.sender] == 0, "Sorry, you have already placed a bet");
    require (msg.value > 0.001 ether, "Error! You have to bet more than 0.001 ether");
    require((block.timestamp < betEndTime) , "Sorry! The betting window is over! ");

    bets.push(Bet(_assetName, msg.sender, msg.value, prices[_priceId]));

    // 0 means this person thinks the price will be greater than 
    if (_priceId == 0) {
        prices[0].totalBetAmount += msg.value;
    } 
    // 0 means this person thinks the price will be less than 
    if (_priceId == 1) {
        pricess[1].totalBetAmount += msg.value;
    }

    (bool sent, bytes memory data) = betContractOwner.call{value: msg.value}("");
    require(sent, "Failed to send Ether. Try again.");

    totalBetMoney += msg.value;

    emit NewBet(msg.sender, msg.value, prices[_priceId]);
}

// Distribute the funds to the winners. Only the owner of the contract can set the winner. Should connect to data oracle...
function betWinDistribution(uint _priceId) public payable onlyOwner() {
        
    uint div;

    if (_priceId == 0) {
        for (uint i = 0; i < bets.length; i++) {
            if (keccak256(abi.encodePacked((bets[i].priceBet.name))) == keccak256(abi.encodePacked("greaterThanBetters"))) {
                address payable receiver = payable(bets[i].adrs);
                div = (bets[i].amount * (10000 + (getTotalBetAmount(1) * 10000 / getTotalBetAmount(0)))) / 10000;

                (bool sent, bytes memory data) = receiver.call{ value: div }("");
                require(sent, "Failed to send Ether");

            }
        }
    } else {
        for (uint i = 0; i < bets.length; i++) {
            if (keccak256(abi.encodePacked((bets[i].teamBet.name))) == keccak256(abi.encodePacked("lessThanBetters"))) {
                address payable receiver = payable(bets[i].adrs);
                div = (bets[i].amount * (10000 + (getTotalBetAmount(0) * 10000 / getTotalBetAmount(1)))) / 10000;

                (bool sent, bytes memory data) = receiver.call{ value: div }("");
                require(sent, "Failed to send Ether");
            }
        }
    }

    totalBetMoney = 0;
    prices[0].totalBetAmount = 0;
    prices[1].totalBetAmount = 0;

    for (uint i = 0; i < bets.length; i++) {
        numBetsAddress[bets[i].adrs] = 0;
    }

}
}