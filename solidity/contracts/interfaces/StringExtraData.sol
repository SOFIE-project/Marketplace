pragma solidity ^0.5.8;


interface JsonStringExtraData {
    function submitOfferJsonStringExtra(uint offerID, string calldata extra) external returns (int status, uint offID);

    function submitRequestJsonStringExtra(uint requestID, string calldata extra) external returns (int status, uint reqID);
}