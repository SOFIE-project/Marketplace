pragma solidity ^0.5.8;


interface ManageableMarketPlace {
    function submitRequest(uint deadline) external returns (int status, uint requestID);

    function closeRequest(uint requestIdentifier) external returns (int status);

    function decideRequest(uint requestIdentifier, uint[] calldata /*acceptedOfferIDs*/) external returns (int status);

    function deleteRequest(uint requestIdentifier) external returns (int status);
}