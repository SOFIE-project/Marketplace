pragma solidity ^0.5.8;


interface ArrayExtraData {
    function submitOfferArrayExtra(uint offerID, uint[] calldata extra) external returns (int status, uint offID);

    function submitRequestArrayExtra(uint requestID, uint[] calldata extra) external returns (int status, uint reqID);
}