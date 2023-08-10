// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';



contract DataConsumerV3 {
    
    AggregatorV3Interface internal dataFeed;
    int public tokenPrice;


    function _getLatestData(uint256 blockchainID) public payable{
        
    
        uint256 USDC = 1; //set token price fetching for matic
        uint256 BNB = 2; //set token price fetching for bnb
        require (blockchainID>0 && blockchainID < BNB, "Invalid blockchain ID");

        address USDC_ADDRESS = 0xefb7e6be8356cCc6827799B6A7348eE674A80EaE;
        address BNB_ADDRESS = 0xc546d2d06144F9DD42815b8bA46Ee7B8FcAFa4a2;

        if(blockchainID == USDC){
            dataFeed = AggregatorV3Interface(
                USDC_ADDRESS//substitute with parameter
            );

            (
                /* uint80 roundID */,
                int answer,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = dataFeed.latestRoundData();
            tokenPrice = answer;
        }

        if(blockchainID == BNB){
            dataFeed = AggregatorV3Interface(
                BNB_ADDRESS//substitute with parameter
            );

            (
                /* uint80 roundID */,
                int answer,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = dataFeed.latestRoundData();
            tokenPrice = answer;
            
        }
    }

    function getLatestData(uint256 blockchainID) public payable{
        
        int answer = 6;
        tokenPrice= answer/int(blockchainID);
        
    }
}
