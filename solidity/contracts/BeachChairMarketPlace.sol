// Licensed to the Apache Software Foundation (ASF) under one or more
// contributor license agreements.  See the NOTICE file distributed
// with this work for additional information regarding copyright
// ownership.  The ASF licenses this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this file
// except in compliance with the License.  You may obtain a copy of the
// License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied.  See the License for the specific language governing
// permissions and limitations under the License.

pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

import "./interfaces/MarketPlace.sol";
import "./interfaces/ArrayExtraData.sol";
import "./interfaces/ManageableMarketPlace.sol";
import "./base/MultiManagersBaseContract.sol";

contract BeachChairMarketPlace is MarketPlace, MultiManagersBaseContract, ArrayExtraData, ManageableMarketPlace {

    enum Stage {Pending, Open, Closed}

    struct Request {
        uint ID;
        uint quantity;
        uint date;
        uint deadline;
        bool isDefined;
        Stage reqStage;
        bool isDecided;
        uint[] offerIDs;
        uint[] acceptedOfferIDs;
        mapping (address => bool) alreadySentOffer;
        uint closingBlock;
    }

    struct Offer {
        uint ID;
        uint quantity;
        uint totalPrice;
        uint requestID;
        address offerMaker;
        bool isDefined;
        Stage offStage;
    }

    uint waitBeforeDeleteBlocks;

    uint private reqNum;
    uint private offNum;
    mapping (uint => Request) private requests;
    mapping (uint => Offer) private offers;

    uint[] private openRequestIDs;
    uint[] private closedRequestIDs;

    event RequestAdded(uint requestID, uint deadline);
    event RequestExtraAdded(uint requestID);
    event OfferAdded(uint offerID, uint requestID, address offerMaker);
    event OfferExtraAdded(uint offerID);

    constructor() MultiManagersBaseContract(msg.sender) public {
        reqNum = 1;
        offNum = 1;
        waitBeforeDeleteBlocks = 1;
        _registerInterface(this.getMarketInformation.selector
                            ^ this.getOpenRequestIdentifiers.selector
                            ^ this.getClosedRequestIdentifiers.selector
                            ^ this.getRequest.selector
                            ^ this.getRequestOfferIDs.selector
                            ^ this.isOfferDefined.selector
                            ^ this.getOffer.selector
                            ^ this.submitOffer.selector
                            ^ this.isRequestDefined.selector
                            ^ this.isRequestDecided.selector
                            ^ this.getRequestDecision.selector);

        _registerInterface(this.submitOfferArrayExtra.selector
                            ^ this.submitRequestArrayExtra.selector);

        _registerInterface(this.submitRequest.selector
                            ^ this.closeRequest.selector
                            ^ this.decideRequest.selector
                            ^ this.deleteRequest.selector);
    }


    // Get the information of market, for example the owner, etc.
    function getMarketInformation() public view returns (int status, address ownerAddress) {
        return (int(Status.Successful), owner());
    }

    // Get the Identifiers of the requests which are not closed yet.
    function getOpenRequestIdentifiers() public view returns (int status, uint[] memory) {
        return (int(Status.Successful), openRequestIDs);
    }

    // Get the Identifiers of the requests which are closed.
    function getClosedRequestIdentifiers() public view returns (int status, uint[] memory) {
        return (int(Status.Successful), closedRequestIDs);
    }

    // Get general details of a request.
    function getRequest(uint requestIdentifier) public view returns (int status, uint deadline, uint stage) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), 0, 0);
        }
        require(requests[requestIdentifier].isDefined);

        return (int(Status.Successful), requests[requestIdentifier].deadline, uint(requests[requestIdentifier].reqStage));
    }

    // Get specific details of a request.
    function getRequestExtra(uint requestIdentifier) public view returns (int status, uint quantity, uint date) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), 0, 0);
        }
        require(requests[requestIdentifier].isDefined);

        return (int(Status.Successful), requests[requestIdentifier].quantity, requests[requestIdentifier].date);
    }

    // Get offer identifiers for a request.
    function getRequestOfferIDs(uint requestIdentifier) public view returns (int status, uint[] memory offerIDs) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), new uint[](0));
        }
        require(requests[requestIdentifier].isDefined);

        return (int(Status.Successful), requests[requestIdentifier].offerIDs);
    }

    // Check if an offer with the specified offer identifier is defined.
    function isOfferDefined(uint offerIdentifier) public view returns (int status, bool) {
        return (int(Status.Successful), offers[offerIdentifier].isDefined);
    }

    // Get general details of an offer.
    function getOffer(uint offerIdentifier) public view returns (int status, uint requestID, address offerMaker, uint stage) {
        if(!offers[offerIdentifier].isDefined) {
            return (int(Status.UndefinedID), 0, address(0), 0);
        }
        require(offers[offerIdentifier].isDefined);

        return (int(Status.Successful), offers[offerIdentifier].requestID, offers[offerIdentifier].offerMaker, uint(offers[offerIdentifier].offStage));
    }

    // Get specific details of an offer.
    function getOfferExtra(uint offerIdentifier) public view returns (int status, uint quantity, uint totalPrice) {
        if(!offers[offerIdentifier].isDefined) {
            return (int(Status.UndefinedID), 0, 0);
        }
        require(offers[offerIdentifier].isDefined);

        return (int(Status.Successful), offers[offerIdentifier].quantity, offers[offerIdentifier].totalPrice);
    }

    // By sending the identifier of a request, others can make offer to rent beach chairs. Each address can only
    // make one offer. After sending the first offer, every other offer sent from that address will be ignored.
    function submitOffer(uint requestID) public returns (int status, uint offerID) {
        if(!requests[requestID].isDefined) {
            emit FunctionStatus(int(Status.UndefinedID));
            return (int(Status.UndefinedID), 0);
        }
        if(now > requests[requestID].deadline) {
            emit FunctionStatus(int(Status.DeadlinePassed));
            return (int(Status.DeadlinePassed), 0);
        }
        if(requests[requestID].reqStage != Stage.Open) {
            emit FunctionStatus(int(Status.RequestNotOpen));
            return (int(Status.RequestNotOpen), 0);
        }
        if(requests[requestID].alreadySentOffer[msg.sender]) {
            emit FunctionStatus(int(Status.AlreadySentOffer));
            return (int(Status.AlreadySentOffer), 0);
        }
        require(requests[requestID].isDefined && now <= requests[requestID].deadline
            && requests[requestID].reqStage == Stage.Open && !requests[requestID].alreadySentOffer[msg.sender]);

        requests[requestID].alreadySentOffer[msg.sender] = true;

        Offer memory offer;
        offer.requestID = requestID;
        offer.offerMaker = msg.sender;
        offer.ID = offNum;
        offNum += 1;
        offer.isDefined = true;
        offer.offStage = Stage.Pending;
        offers[offer.ID] = offer;
        requests[offer.requestID].offerIDs.push(offer.ID);
        emit FunctionStatus(int(Status.Successful));
        emit OfferAdded(offer.ID, offer.requestID, offer.offerMaker);
        return (int(Status.Successful), offer.ID);
    }

    // By adding the proposed quantity, and the total price, others can complete and open their offer
    // (only the initial offer maker can access this function).
    function submitOfferArrayExtra(uint offerID, uint[] calldata extra) external returns (int status, uint offID) {
        Offer memory offer = offers[offerID];

        if(!offer.isDefined) {
            emit FunctionStatus(int(Status.UndefinedID));
            return (int(Status.UndefinedID), 0);
        }
        if(offer.offStage != Stage.Pending) {
            emit FunctionStatus(int(Status.NotPending));
            return (int(Status.NotPending), 0);
        }
        if(offer.offerMaker != msg.sender) {
            emit FunctionStatus(int(Status.AccessDenied));
            return (int(Status.AccessDenied), 0);
        }
        if(requests[offer.requestID].reqStage != Stage.Open) {
            emit FunctionStatus(int(Status.RequestNotOpen));
            return (int(Status.RequestNotOpen), 0);
        }
        require(offer.isDefined && offer.offStage == Stage.Pending
            && offer.offerMaker == msg.sender
            && requests[offer.requestID].reqStage == Stage.Open);

        offer.quantity = extra[0];
        offer.totalPrice = extra[1];
        offer.offStage = Stage.Open;
        offers[offerID] = offer;
        emit FunctionStatus(int(Status.Successful));
        emit OfferExtraAdded(offerID);
        return (int(Status.Successful), offerID);
    }

    // Check if a request with the specified request identifier is defined.
    function isRequestDefined(uint requestIdentifier) public view returns (int status, bool) {
        return (int(Status.Successful), requests[requestIdentifier].isDefined);
    }

    // Check if a defined request with the specified request identifier is decided.
    function isRequestDecided(uint requestIdentifier) public view returns (int status, bool) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), false);
        }
        require(requests[requestIdentifier].isDefined);

        return (int(Status.Successful), requests[requestIdentifier].isDecided);
    }

    // Get the identifiers of accepted offers for a decided request.
    function getRequestDecision(uint requestIdentifier) public view returns (int status, uint[] memory acceptedOfferIDs) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), new uint[](0));
        }
        if(!requests[requestIdentifier].isDecided) {
            return (int(Status.ReqNotDecided), new uint[](0));
        }
        require(requests[requestIdentifier].isDefined && requests[requestIdentifier].isDecided);

        return (int(Status.Successful), requests[requestIdentifier].acceptedOfferIDs);
    }

    // By specifiying the deadline of the request,
    // owner and managers can add a new request. It will have a unique identifier and others will be able to make
    // offers for it (only owner or managers can access this function).
    function submitRequest(uint deadline) public returns (int status, uint requestID) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return (int(Status.AccessDenied), 0);
        }
        require(msg.sender == owner() || isManager(msg.sender));

        Request memory request;
        request.deadline = deadline;
        request.ID = reqNum;
        reqNum += 1;
        request.isDefined = true;
        request.reqStage = Stage.Pending;
        request.isDecided = false;
        requests[request.ID] = request;
        emit FunctionStatus(int(Status.Successful));
        emit RequestAdded(request.ID, request.deadline);
        return (int(Status.Successful), request.ID);
    }

    // By adding the quantity of the beach chairs needed, and the intended rental date,
    // owner and managers can complete a request (only owner or managers can access this function).
    function submitRequestArrayExtra(uint requestID, uint[] calldata extra) external returns (int status, uint reqID) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return (int(Status.AccessDenied), 0);
        }
        if(!requests[requestID].isDefined) {
            emit FunctionStatus(int(Status.UndefinedID));
            return (int(Status.UndefinedID), 0);
        }
        if(requests[requestID].reqStage != Stage.Pending) {
            emit FunctionStatus(int(Status.NotPending));
            return (int(Status.NotPending), 0);
        }
        require(msg.sender == owner() || isManager(msg.sender));
        require(requests[requestID].isDefined && requests[requestID].reqStage == Stage.Pending);

        requests[requestID].quantity = extra[0];
        requests[requestID].date = extra[1];
        openRequest(requestID);
        emit FunctionStatus(int(Status.Successful));
        emit RequestExtraAdded(requestID);
        return (int(Status.Successful), requestID);
    }

    // Open a request.
    function openRequest(uint requestIdentifier) private {
        requests[requestIdentifier].reqStage = Stage.Open;
        openRequestIDs.push(requests[requestIdentifier].ID);
    }

    // Manually close a request, so others won't be able to make offers for it or even see it in the list of requests.
    // In this implementation, this is completely apart from request's deadline. This can be modified based on the
    // specifications of the market we have (only owner or managers can access this function).
    function closeRequest(uint requestIdentifier) public returns (int status) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        require(msg.sender == owner() || isManager(msg.sender));

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
                emit FunctionStatus(int(Status.Successful));
                return int(Status.Successful);
            }
        }
    }

    // Check if there is no invalid or redundant offer identifiers among the accepted offer IDs.
    function checkIntegrityOfAcceptedOffersList(uint requestIdentifier, uint[] memory acceptedOfferIDs) private view returns (bool) {
        for (uint j = 0; j < acceptedOfferIDs.length; j++) {
            if (offers[acceptedOfferIDs[j]].requestID != requestIdentifier) {
                return false;
            }
            for (uint i = 0; i < j; i++) {
                if (acceptedOfferIDs[j] == acceptedOfferIDs[i]) {
                    return false;
                }
            }
        }
        return true;
    }

    // By sending the identifiers of offers for a specific request, managers and owners can select the
    // of offers they want to accept. Some validity checks will be performed on the array of accepted offers,
    // before finalizing the decision (only owner or managers can access this function).
    function decideRequest(uint requestIdentifier, uint[] calldata acceptedOfferIDs) external returns (int status) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        bool integrity = checkIntegrityOfAcceptedOffersList(requestIdentifier, acceptedOfferIDs);
        if(!integrity) {
            emit FunctionStatus(int(Status.ImproperList));
            return int(Status.ImproperList);
        }
        require(msg.sender == owner() || isManager(msg.sender));
        require(integrity);

        closeRequest(requestIdentifier);
        requests[requestIdentifier].acceptedOfferIDs = acceptedOfferIDs;
        requests[requestIdentifier].isDecided = true;
        emit FunctionStatus(int(Status.Successful));
        return int(Status.Successful);
    }

    function deleteRequest(uint requestIdentifier) public returns (int status) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        if(requests[requestIdentifier].reqStage != Stage.Closed) {
            emit FunctionStatus(int(Status.ReqNotClosed));
            return int(Status.ReqNotClosed);
        }
        if(requests[requestIdentifier].closingBlock + waitBeforeDeleteBlocks > block.number) {
            emit FunctionStatus(int(Status.NotTimeForDeletion));
            return int(Status.NotTimeForDeletion);
        }
        require(msg.sender == owner() || isManager(msg.sender));
        require(requests[requestIdentifier].reqStage == Stage.Closed
            && requests[requestIdentifier].closingBlock + waitBeforeDeleteBlocks <= block.number);

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
                emit FunctionStatus(int(Status.Successful));
                return int(Status.Successful);
            }
        }
    }
}
