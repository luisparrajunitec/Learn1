// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


contract NFTAuction is ERC721URIStorage, ReentrancyGuard {

    uint256 public tokenCounter;
    uint256 public listingCounter;
    int public tokenPrice;

    uint8 public constant STATUS_OPEN = 1; // open for bidding
    uint8 public constant STATUS_DONE = 2; // auction done 
    uint8 public constant COMISSION = 10; 

    uint256 public minAuctionIncrement = 10; //minimal incremental percentage

    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 price; // display price
        uint256 netPrice; // actual price
        uint256 startAt;
        uint256 endAt; 
        uint8 status;
    }

    //Defining events
    event Minted(address indexed minter, uint256 nftID, string uri);
    event AuctionCreated(uint256 listingId, address indexed seller, uint256 price, uint256 tokenId, uint256 startAt, uint256 endAt);
    event BidCreated(uint256 listingId, address indexed bidder, uint256 bid);
    event AuctionCompleted(uint256 listingId, address indexed seller, address indexed bidder, uint256 bid);
    event WithdrawBid(uint256 listingId, address indexed bidder, uint256 bid);

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => mapping(address => uint256)) public bids;
    mapping(uint256 => address) public highestBidder;

    constructor() ERC721("NFTAuction", "NFTA"   ) {
        tokenCounter = 0;
        listingCounter = 0;
    }

    //first you call this function to create a token
    function mint(string memory tokenURI, address minterAddress) public returns (uint256) {
        tokenCounter++;
        uint256 tokenId = tokenCounter;

        _safeMint(minterAddress, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit Minted(minterAddress, tokenId, tokenURI);

        return tokenId;
    }

    //then you call this function to create a listing
    function createAuctionListing (uint256 price, uint256 tokenId, uint256 durationInSeconds) public returns (uint256) {
        listingCounter++;
        uint256 listingId = listingCounter;

        uint256 startAt = block.timestamp;
        uint256 endAt = startAt + durationInSeconds;

        listings[listingId] = Listing({
            seller: msg.sender,
            tokenId: tokenId,
            price: price,
            netPrice: price,
            status: STATUS_OPEN,
            startAt: startAt,
            endAt: endAt
        });

        _transfer(msg.sender, address(this), tokenId);

        emit AuctionCreated(listingId, msg.sender, price, tokenId, startAt, endAt);

        return listingId;
    }

    //bids work incrementally meaning that in every bid you make you are simply adding to your already existing bid
    function bid(uint256 listingId) public payable nonReentrant {
        require(isAuctionOpen(listingId), 'Auction is not open!');
        Listing storage listing = listings[listingId];
        require(msg.sender != listing.seller, "You cannot bid on what you own!");

        uint256 newBid = bids[listingId][msg.sender] + msg.value;
        require(newBid >= listing.price, "You cannot bid below the latest bidding price");

        bids[listingId][msg.sender] += msg.value;
        highestBidder[listingId] = msg.sender;

        uint256 incentive = listing.price / minAuctionIncrement;
        listing.price = listing.price + incentive;

        emit BidCreated(listingId, msg.sender, newBid);
    }

    function isAuctionOpen(uint256 id) public view returns (bool) {
        return
            listings[id].status == STATUS_OPEN &&
            listings[id].endAt > block.timestamp;
    }

    function isAuctionExpired(uint256 id) public view returns (bool) {
        return listings[id].endAt <= block.timestamp;
    }


    function completeAuction(uint256 listingId) public payable nonReentrant {
        require(!isAuctionOpen(listingId), 'The auction is still open');

        Listing storage listing = listings[listingId];
        address winner = highestBidder[listingId]; 
        require(
            msg.sender == listing.seller || msg.sender == winner, 
            'Only seller or winner can complete the auction!'
        );

        if(winner != address(0)) {
           _transfer(address(this), winner, listing.tokenId);

            uint256 amount = bids[listingId][winner]; 
            bids[listingId][winner] = 0;
            _transferFund(payable(listing.seller), amount * (100 - COMISSION) / 100);

        } else {
            _transfer(address(this), listing.seller, listing.tokenId);
        }

        listing.status = STATUS_DONE;

        emit AuctionCompleted(listingId, listing.seller, winner, bids[listingId][winner]);
    }


    function withdrawBid(uint256 listingId) public payable nonReentrant {
        require(isAuctionExpired(listingId), 'Auction must be ended');
        require(highestBidder[listingId] != msg.sender, 'Highest bidder cannot withdraw bid');

        uint256 balance = bids[listingId][msg.sender];
        bids[listingId][msg.sender] = 0;
        _transferFund(payable(msg.sender), balance);

        emit WithdrawBid(listingId, msg.sender, balance);

    }


    function _transferFund(address payable to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        require(to != address(0), 'Error, cannot transfer to address(0)');

        (bool transferSent, ) = to.call{value: amount}("");
        require(transferSent, "Error, failed to send Ether");
    }


    function getLatestData(uint256 blockchainID, address source) public payable{

        (bool success, bytes memory data) = source.delegatecall(
            abi.encodeWithSignature("getLatestData(uint256)", blockchainID)
        );
        require(success, "Unable to fetch token price");
    }
    
    /*function set_source(uint256 tokenID, address dataSource){
        
    }

    function freeze_set_source(address newSource, bool freezed){

    }*/


}