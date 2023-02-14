// // SPDX-License-Identifier: GPL - 3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract Auction{
    address payable public auctoner;
    uint public stblock;
    uint public etblock;

    enum Auc_state {Started,Running,Ended,Cancelled}
    Auc_state public auctionState;

    uint public highestPayableBid;
    uint public bidInc;

    address payable public highestBidder;

    mapping(address => uint) public bids;

    constructor(){
        auctoner = payable(msg.sender);
        auctionState = Auc_state.Running;
        stblock = block.number;
        etblock = stblock + 240;
        bidInc = 1 ether; 
    }

    modifier notOwner(){
        require(msg.sender != auctoner," Owner can not bid");
        _;
    }

    modifier owner(){
        require(msg.sender == auctoner," Only Owner can modify ");
        _;
    }

    modifier started(){
        require(block.number > stblock);
        _;
    }

    modifier beforeEnding(){
        require(block.number < etblock);
        _;
    }

    function min(uint a,uint b) pure public returns(uint) {
        if(a > b) return b;
        else return a;
    }

    function cancelled() public owner{
        auctionState = Auc_state.Cancelled;
    }

    function endedAuc() public owner{
        auctionState = Auc_state.Ended;
    }

    function bid() payable public notOwner started beforeEnding{
        require(auctionState == Auc_state.Running);
        require(msg.value >= 1);

        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestPayableBid);

        bids[msg.sender] = currentBid;

        if(currentBid<bids[highestBidder]){
            highestPayableBid = min(currentBid + bidInc, bids[highestBidder]);
        } else{
            highestPayableBid = min(currentBid , bids[highestBidder] + bidInc);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuc() public {
        require(auctionState == Auc_state.Cancelled || auctionState == Auc_state.Ended || block.number > etblock);
        require(msg.sender == auctoner || bids[msg.sender]>0);

        address payable person;
        uint value;

        if(auctionState == Auc_state.Cancelled){
            person = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if(msg.sender == auctoner){
                person = auctoner;
                value = highestPayableBid;
            }
            else{
                if(msg.sender == highestBidder){
                    person = highestBidder;
                    value = bids[highestBidder] - highestPayableBid;
                }
                else {
                    person = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender] = 0;
        person.transfer(value);
    }
}
