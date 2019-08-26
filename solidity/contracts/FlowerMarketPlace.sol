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
import "./interfaces/ManageableMarketPlace.sol";
import "./interfaces/ArrayExtraData.sol";
import "./base/MultiManagersBaseContract.sol";

contract FlowerMarketPlace is MarketPlace, MultiManagersBaseContract, ManageableMarketPlace, ArrayExtraData {

    enum Stage {Pending, Open, Closed}

    enum FlowerType {Rose, Tulip, Jasmine, White}

    struct Request {
        uint ID;
        uint quantity;
        FlowerType flowerType;
        uint deadline;
        bool isDefined;
        Stage reqStage;
        bool isDecided;
        uint[] offerIDs;
        uint acceptedOfferID;
        uint closingBlock;
    }

    struct Offer {
        uint ID;
        uint price;
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
    function getMarketInformation() public view returns (uint8 status, address ownerAddress) {
        return (Successful, owner());
    }

    // Get the Identifiers of the requests which are not closed yet.
    function getOpenRequestIdentifiers() public view returns (uint8 status, uint[] memory) {
        return (Successful, openRequestIDs);
    }

    // Get the Identifiers of the requests which are closed.
    function getClosedRequestIdentifiers() public view returns (uint8 status, uint[] memory) {
        return (Successful, closedRequestIDs);
    }

    // Get general details of a request.
    function getRequest(uint requestIdentifier) public view returns (uint8 status, uint deadline, uint stage) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, 0, 0);
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requests[requestIdentifier].deadline, uint(requests[requestIdentifier].reqStage));
    }

    // Get the specific stipulations of a request.
    function getRequestExtra(uint requestIdentifier) public view returns (uint8 status, uint quantity, FlowerType flowerType) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, 0, FlowerType(0));
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requests[requestIdentifier].quantity, requests[requestIdentifier].flowerType);
    }

    // Get offer identifiers for a request.
    function getRequestOfferIDs(uint requestIdentifier) public view returns (uint8 status, uint[] memory offerIDs) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, new uint[](0));
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requests[requestIdentifier].offerIDs);
    }

    // Check if an offer with the specified offer identifier is defined.
    function isOfferDefined(uint offerIdentifier) public view returns (uint8 status, bool) {
        return (Successful, offers[offerIdentifier].isDefined);
    }

    // Get general details of an offer.
    function getOffer(uint offerIdentifier) public view returns (uint8 status, uint requestID, address offerMaker, uint stage) {
        if(!offers[offerIdentifier].isDefined) {
            return (UndefinedID, 0, address(0), 0);
        }
        require(offers[offerIdentifier].isDefined);

        return (Successful, offers[offerIdentifier].requestID, offers[offerIdentifier].offerMaker, uint(offers[offerIdentifier].offStage));
    }

    // Get specific details of an offer.
    function getOfferExtra(uint offerIdentifier) public view returns (uint8 status, uint price) {
        if(!offers[offerIdentifier].isDefined) {
            return (UndefinedID, 0);
        }
        require(offers[offerIdentifier].isDefined);

        return (Successful, offers[offerIdentifier].price);
    }

    // By sending the identifier of a request, others can make offer to buy flowers.
    function submitOffer(uint requestID) public returns (uint8 status, uint offerID) {
        if(!requests[requestID].isDefined) {
            emit FunctionStatus(UndefinedID);
            return (UndefinedID, 0);
        }
        if(now > requests[requestID].deadline) {
            emit FunctionStatus(DeadlinePassed);
            return (DeadlinePassed, 0);
        }
        if(requests[requestID].reqStage != Stage.Open) {
            emit FunctionStatus(RequestNotOpen);
            return (RequestNotOpen, 0);
        }
        require(requests[requestID].isDefined && now <= requests[requestID].deadline
            && requests[requestID].reqStage == Stage.Open);

        Offer memory offer;
        offer.requestID = requestID;
        offer.offerMaker = msg.sender;
        offer.ID = offNum;
        offNum += 1;
        offer.isDefined = true;
        offer.offStage = Stage.Pending;
        offers[offer.ID] = offer;
        requests[offer.requestID].offerIDs.push(offer.ID);
        emit FunctionStatus(Successful);
        emit OfferAdded(offer.ID, offer.requestID, offer.offerMaker);
        return (Successful, offer.ID);
    }

    // By sending the proposed price, others can complete and open their offer to buy flowers.
    // (only the initial offer maker can access this function).
    function submitOfferArrayExtra(uint offerID, uint[] calldata extra) external returns (uint8 status, uint offID) {
        Offer memory offer = offers[offerID];

        if(!offer.isDefined) {
            emit FunctionStatus(UndefinedID);
            return (UndefinedID, 0);
        }
        if(offer.offStage != Stage.Pending) {
            emit FunctionStatus(NotPending);
            return (NotPending, 0);
        }
        if(offer.offerMaker != msg.sender) {
            emit FunctionStatus(AccessDenied);
            return (AccessDenied, 0);
        }
        if(requests[offer.requestID].reqStage != Stage.Open) {
            emit FunctionStatus(RequestNotOpen);
            return (RequestNotOpen, 0);
        }
        require(offer.isDefined && offer.offStage == Stage.Pending
            && offer.offerMaker == msg.sender
            && requests[offer.requestID].reqStage == Stage.Open);

        offer.price = extra[0];
        offer.offStage = Stage.Open;
        offers[offerID] = offer;
        emit FunctionStatus(Successful);
        emit OfferExtraAdded(offerID);
        return (Successful, offerID);
    }

    // Check if a request with the specified request identifier is defined.
    function isRequestDefined(uint requestIdentifier) public view returns (uint8 status, bool) {
        return (Successful, requests[requestIdentifier].isDefined);
    }

    // Check if a defined request with the specified request identifier is decided.
    function isRequestDecided(uint requestIdentifier) public view returns (uint8 status, bool) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, false);
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requests[requestIdentifier].isDecided);
    }

    // Get the identifier of accepted offer for a decided request.
    function getRequestDecision(uint requestIdentifier) public view returns (uint8 status, uint[] memory acceptedOfferIDs) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, new uint[](0));
        }
        if(!requests[requestIdentifier].isDecided) {
            return (ReqNotDecided, new uint[](0));
        }
        require(requests[requestIdentifier].isDefined && requests[requestIdentifier].isDecided);

        if(requests[requestIdentifier].acceptedOfferID != 0) {
            uint[] memory accoffIDs1 = new uint[](1);
            accoffIDs1[0] = requests[requestIdentifier].acceptedOfferID;
            return (Successful, accoffIDs1);
        }
        else {
            uint[] memory accoffIDs2 = new uint[](0);
            return (Successful, accoffIDs2);
        }
    }

    // By specifiying the deadline of the request, owner and managers
    // can add a new request. It will have a unique identifier and others will be able to make offers for it
    // (only owner or managers can access this function).
    function submitRequest(uint deadline) public returns (uint8 status, uint requestID) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return (AccessDenied, 0);
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
        emit FunctionStatus(Successful);
        emit RequestAdded(request.ID, request.deadline);
        return (Successful, request.ID);
    }

    // By specifiying the type of the flowers, quantity of them, owner and managers
    // can complete a request (only owner or managers can access this function).
    function submitRequestArrayExtra(uint requestID, uint[] calldata extra) external returns (uint8 status, uint reqID) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return (AccessDenied, 0);
        }
        if(!requests[requestID].isDefined) {
            emit FunctionStatus(UndefinedID);
            return (UndefinedID, 0);
        }
        if(requests[requestID].reqStage != Stage.Pending) {
            emit FunctionStatus(NotPending);
            return (NotPending, 0);
        }
        require(msg.sender == owner() || isManager(msg.sender));
        require(requests[requestID].isDefined && requests[requestID].reqStage == Stage.Pending);

        requests[requestID].quantity = extra[0];
        requests[requestID].flowerType = FlowerType(extra[1]);
        openRequest(requestID);
        emit FunctionStatus(Successful);
        emit RequestExtraAdded(requestID);
        return (Successful, requestID);
    }

    // Open a request.
    function openRequest(uint requestIdentifier) private {
        requests[requestIdentifier].reqStage = Stage.Open;
        openRequestIDs.push(requests[requestIdentifier].ID);
    }

    // Manually close a request, so others won't be able to make offers for it or even see it in the list of requests.
    // In this implementation, this is completely apart from request's deadline. This can be modified based on the
    // specifications of the market we have (only owner or managers can access this function).
    function closeRequest(uint requestIdentifier) public returns (uint8 status) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
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
                emit FunctionStatus(Successful);
                return Successful;
            }
        }
    }

    // Choose which offer to accept, based on the proposed prices. The decision process can differ for other markets,
    // and it can be very complicated. Even in some cases, the decision must be made in the backend.
    // (only owner or managers can access this function).
    function decideRequest(uint requestIdentifier, uint[] calldata /*acceptedOfferIDs*/) external returns (uint8 status) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        require(msg.sender == owner() || isManager(msg.sender));

        closeRequest(requestIdentifier);
        uint maxOffer = 0;
        uint acceptedOfferID = 0;
        for (uint i = 0; i < requests[requestIdentifier].offerIDs.length; i++) {
            Offer memory offer = offers[requests[requestIdentifier].offerIDs[i]];
            if (offer.offStage == Stage.Open && maxOffer < offer.price) {
                maxOffer = offer.price;
                acceptedOfferID = requests[requestIdentifier].offerIDs[i];
            }
        }
        requests[requestIdentifier].acceptedOfferID = acceptedOfferID;
        requests[requestIdentifier].isDecided = true;
        emit FunctionStatus(Successful);
        return Successful;
    }

    function deleteRequest(uint requestIdentifier) public returns (uint8 status) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        if(requests[requestIdentifier].reqStage != Stage.Closed) {
            emit FunctionStatus(ReqNotClosed);
            return ReqNotClosed;
        }
        if(requests[requestIdentifier].closingBlock + waitBeforeDeleteBlocks > block.number) {
            emit FunctionStatus(NotTimeForDeletion);
            return NotTimeForDeletion;
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
                emit FunctionStatus(Successful);
                return Successful;
            }
        }
    }

    // Returns the type of marketplace.
    function getType() external view returns (uint8 status, string memory) {
        return (Successful, "eu.sofie-iot.offer-marketplace-demo.flower");
    }

}
