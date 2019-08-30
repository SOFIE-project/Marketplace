pragma solidity ^0.5.8;

import "../interfaces/ManageableMarketPlace.sol";
import "./AbstractMarketPlace.sol";

contract AbstractManageableMarketPlace is AbstractMarketPlace, ManageableMarketPlace {

    constructor() AbstractMarketPlace() ManageableMarketPlace() public {
        _registerInterface(this.submitRequest.selector
                            ^ this.closeRequest.selector
                            ^ this.decideRequest.selector
                            ^ this.deleteRequest.selector);
    }

    function openRequest(uint requestIdentifier) internal {
        requests[requestIdentifier].reqStage = Stage.Open;
        openRequestIDs.push(requests[requestIdentifier].ID);
    }

    function finishSubmitRequestExtra(uint requestIdentifier) internal returns (uint8 status, uint requestID) {
        openRequest(requestIdentifier);
        emit FunctionStatus(Successful);
        emit RequestExtraAdded(requestIdentifier);
        return (Successful, requestIdentifier);
    }

    function submitRequest(uint deadline) public returns (uint8 status, uint requestID) {
        Request memory request;
        request.deadline = deadline;
        request.ID = reqNum;
        reqNum += 1;
        request.isDefined = true;
        request.reqStage = Stage.Pending;
        request.isDecided = false;
        requests[request.ID] = request;
        emit FunctionStatus(Successful);
        emit RequestAdded(request.ID, request.deadline);
    }

    function closeRequest(uint requestIdentifier) public returns (uint8 status) {
        requests[requestIdentifier].reqStage = Stage.Closed;
        requests[requestIdentifier].closingBlock = block.number;
        closedRequestIDs.push(requestIdentifier);
        for (uint j = 0; j < openRequestIDs.length; j++) {
            if (openRequestIDs[j] == requestIdentifier) {
                for (uint i = j; i < openRequestIDs.length - 1; i++){
                    openRequestIDs[i] = openRequestIDs[i+1];
                }
                delete openRequestIDs[openRequestIDs.length-1];
                openRequestIDs.length--;
                emit FunctionStatus(Successful);
                return Successful;
            }
        }
    }

    function decideRequest(uint requestIdentifier, uint[] calldata /*acceptedOfferIDs*/) external returns (uint8 status);

    function _decideRequest(uint requestIdentifier, uint[] memory acceptedOfferIDs) internal returns(uint8 status) {
        closeRequest(requestIdentifier);
        requests[requestIdentifier].acceptedOfferIDs = acceptedOfferIDs;
        requests[requestIdentifier].isDecided = true;
        emit FunctionStatus(Successful);
        return Successful;
    }

    function deleteRequest(uint requestIdentifier) public returns (uint8 status) {
        for (uint k = 0; k < requests[requestIdentifier].offerIDs.length; k++) {
            delete offers[requests[requestIdentifier].offerIDs[k]];
        }

        delete requests[requestIdentifier];

        for (uint j = 0; j < closedRequestIDs.length; j++) {
            if (closedRequestIDs[j] == requestIdentifier) {
                for (uint i = j; i < closedRequestIDs.length - 1; i++){
                    closedRequestIDs[i] = closedRequestIDs[i+1];
                }
                delete closedRequestIDs[closedRequestIDs.length-1];
                closedRequestIDs.length--;
                emit FunctionStatus(Successful);
                return Successful;
            }
        }
    }
}