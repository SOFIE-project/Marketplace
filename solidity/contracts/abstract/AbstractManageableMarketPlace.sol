pragma solidity ^0.5.8;

import "../interfaces/ManageableMarketPlace.sol";
import "./AbstractMarketPlace.sol";

contract AbstractManageableMarketPlace is AbstractMarketPlace, ManageableMarketPlace {

    event RequestDecided(uint requestID, uint[] winningOffersIDs);
    event RequestClosed(uint requestID);

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
        request.requestMaker = msg.sender;
        requests[request.ID] = request;
        emit FunctionStatus(Successful);
        emit RequestAdded(request.ID, request.deadline);
        return (Successful, request.ID);
    }

    function closeRequestInsecure(uint requestIdentifier) internal returns (uint8 status) {
        // close the request, update relevant data & emit events
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
                emit RequestClosed(requestIdentifier);
                return Successful;
            }
        }
    }

    function closeRequest(uint requestIdentifier) public returns (uint8 status) {
        // check request existance
        (, bool isRequestDefined) = isRequestDefined(requestIdentifier);

        if (!isRequestDefined) {
            emit FunctionStatus(UndefinedID);
            return UndefinedID;
        }

        closeRequestInsecure(requestIdentifier);
    }

    // function decideRequest(uint requestIdentifier, uint[] calldata /*acceptedOfferIDs*/) external returns (uint8 status);

    function decideRequestInsecure(uint requestIdentifier, uint[] memory acceptedOfferIDs) internal returns(uint8 status) {
        // close the request, update relevant data & emit events
        closeRequestInsecure(requestIdentifier);
        requests[requestIdentifier].acceptedOfferIDs = acceptedOfferIDs;
        requests[requestIdentifier].isDecided = true;
        requests[requestIdentifier].decisionTime = now;
        emit FunctionStatus(Successful);
        emit RequestDecided(requestIdentifier, acceptedOfferIDs);
        return Successful;
    }

    function decideRequest(uint requestIdentifier, uint[] memory acceptedOfferIDs) public returns(uint8 status) {
        // check request existance
        (, bool isRequestDefined) = isRequestDefined(requestIdentifier);

        if (!isRequestDefined) {
            emit FunctionStatus(UndefinedID);
            return UndefinedID;
        }

        return decideRequestInsecure(requestIdentifier, acceptedOfferIDs);
    }

    function deleteRequestInsecure(uint requestIdentifier) internal returns (uint8 status) {
        // delete request & update relevant data
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

    function deleteRequest(uint requestIdentifier) public returns (uint8 status) {
        // check request existance
        (, bool isRequestDefined) = isRequestDefined(requestIdentifier);

        if (!isRequestDefined) {
            emit FunctionStatus(UndefinedID);
            return UndefinedID;
        }

        deleteRequestInsecure(requestIdentifier);
    }

    function submitOffer(uint requestID) public returns (uint8 status, uint offerID) {
        (, bool isRequestDefined) = isRequestDefined(requestID);
        if (!isRequestDefined) {
            emit FunctionStatus(UndefinedID);
            return (UndefinedID, 0);
        }

        Request storage request = requests[requestID];

        // if(now > request.deadline) {
        //     emit FunctionStatus(DeadlinePassed);
        //     return (DeadlinePassed, 0);
        // } // it is optional to use the request deadline

        if(request.reqStage != Stage.Open) {
            emit FunctionStatus(RequestNotOpen);
            return (RequestNotOpen, 0);
        }
        return super.submitOffer(requestID);
    }
}