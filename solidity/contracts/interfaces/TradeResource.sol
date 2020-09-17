pragma solidity ^0.5.8;


interface TradeResource {
    event TradeSettled(uint requestID, uint offerID);

    function settleTrade(uint requestID, uint offerID) external returns (uint8 status);
}