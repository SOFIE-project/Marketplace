pragma solidity ^0.5.8;


interface ManageableMarketPlace {
    function submitRequest(uint deadline) external returns (uint8 status, uint requestID);

    function closeRequest(uint requestIdentifier) external returns (uint8 status);

    function decideRequest(uint requestIdentifier, uint[] calldata /*acceptedOfferIDs*/) external returns (uint8 status);

    function deleteRequest(uint requestIdentifier) external returns (uint8 status);
}