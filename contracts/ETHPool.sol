//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract ETHPool {
    address public owner;
    uint256 public ethpool;
    Deposit[] public rewards;

    struct Deposit {
        uint256 amount;
        uint256 atTime;
    }

    struct Investor {
        uint256 totalInvested;
        uint256 firstInvesting;
        uint256 lastInvesting;
    }

    mapping(address => Investor) investors;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        require(msg.sender != owner, "The owner can't invest in the pool");
        if (investors[msg.sender].firstInvesting == 0) investors[msg.sender].firstInvesting = block.number;
        investors[msg.sender].lastInvesting = block.number;
        investors[msg.sender].totalInvested += msg.value;

    }

    function addWeeklyRewards(uint256 _amount) public payable {
        require(msg.sender == owner, "Only the owner can deposit rewards");
        require(_amount > 0, "The rewards must be greater than zero");
        rewards.push(Deposit(_amount, block.number));
    }

    function calculateRewards(uint256 _percentage) internal returns (uint256 _rewards) {
        //pasarle el porcentaje que tiene que sacarle a cada weekly rewards y ahí comenzar a recorrer
        //el array de rewards, por cada posicion si el block.number es >= block.number de la firstInvesting y <= a la lastInvesting
        //sumarle lo que diga el porcentaje a _rewards y además restarle ese porcentaje al amount de la posicion del array current.
        require(rewards.length > 0, "The contract don't have rewards to withdraw yet!"); 
        for (uint256 i = 0; i < rewards.length; i++) {
            if(rewards[i].atTime >= investors[msg.sender].firstInvesting && rewards[i].atTime <= investors[msg.sender].lastInvesting) {
                _rewards += (_percentage * rewards[i].amount) / 100 ;
                rewards[i].amount -= (_percentage * rewards[i].amount) / 100;
            }
        }
        return _rewards;
    }

    function withdrawMoney() public {
        require(msg.sender != owner, "The owner can't withdraw money of the pool");
        require(investors[msg.sender].totalInvested > 0, "The amount invested must be greater than 0");
        uint256 totalToWithdraw = investors[msg.sender].totalInvested;
        uint256 percentageInvested = (investors[msg.sender].totalInvested / ethpool) * 100;
        uint256 _rewards = calculateRewards(percentageInvested);
        if(_rewards > 0) {
            totalToWithdraw += _rewards;
        }
        ethpool -= investors[msg.sender].totalInvested;
        investors[msg.sender].totalInvested = 0;
        investors[msg.sender].firstInvesting = 0;
        investors[msg.sender].lastInvesting = 0;

        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = msg.sender.call{value: totalToWithdraw}("");
        require(sent, "Transaction failed");
        totalToWithdraw = 0;
    }
}
