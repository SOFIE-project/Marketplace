pragma solidity ^0.5.8;


interface JsonStringOfferExtraData {
    function submitOfferJsonStringExtra(uint offerID, string calldata extra) external payable returns (uint8 status, uint offID);
}


interface JsonStringRequestExtraData {
    function submitRequestJsonStringExtra(uint requestID, string calldata extra) external returns (uint8 status, uint reqID);
}