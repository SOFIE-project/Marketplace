pragma solidity ^0.5.8;


interface ArrayOfferExtraData {
    function submitOfferArrayExtra(uint offerID, uint[] calldata extra) external payable returns (uint8 status, uint offID);
}


interface ArrayRequestExtraData {
    function submitRequestArrayExtra(uint requestID, uint[] calldata extra) external returns (uint8 status, uint reqID);
}