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

import "./interfaces/ArrayExtraData.sol";
import "./abstract/AbstractOwnerManagerMarketPlace.sol";

contract BeachChairMarketPlace is AbstractOwnerManagerMarketPlace, ArrayRequestExtraData, ArrayOfferExtraData {

    struct RequestExtra {
        uint quantity;
        uint date;
        mapping (address => bool) alreadySentOffer;
    }

    struct OfferExtra {
        uint quantity;
        uint totalPrice;
    }

    mapping (uint => RequestExtra) private requestsExtra;
    mapping (uint => OfferExtra) private offersExtra;

    constructor() public {
        _registerInterface(this.submitOfferArrayExtra.selector
                            ^ this.submitRequestArrayExtra.selector);
    }

    // Get specific details of a request.
    function getRequestExtra(uint requestIdentifier) public view returns (uint8 status, uint quantity, uint date) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, 0, 0);
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requestsExtra[requestIdentifier].quantity, requestsExtra[requestIdentifier].date);
    }

    // Get specific details of an offer.
    function getOfferExtra(uint offerIdentifier) public view returns (uint8 status, uint quantity, uint totalPrice) {
        if(!offers[offerIdentifier].isDefined) {
            return (UndefinedID, 0, 0);
        }
        require(offers[offerIdentifier].isDefined);

        return (Successful, offersExtra[offerIdentifier].quantity, offersExtra[offerIdentifier].totalPrice);
    }

    // By sending the identifier of a request, others can make offer to rent beach chairs. Each address can only
    // make one offer. After sending the first offer, every other offer sent from that address will be ignored.
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
        if(requestsExtra[requestID].alreadySentOffer[msg.sender]) {
            emit FunctionStatus(AlreadySentOffer);
            return (AlreadySentOffer, 0);
        }
        require(requests[requestID].isDefined && now <= requests[requestID].deadline
            && requests[requestID].reqStage == Stage.Open && !requestsExtra[requestID].alreadySentOffer[msg.sender]);

        requestsExtra[requestID].alreadySentOffer[msg.sender] = true;
        return super.submitOffer(requestID);
    }

    // By adding the proposed quantity, and the total price, others can complete and open their offer
    // (only the initial offer maker can access this function).
    function submitOfferArrayExtra(uint offerID, uint[] calldata extra) external payable returns (uint8 status, uint offID) {
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

        OfferExtra memory offerExtra;
        offerExtra.quantity = extra[0];
        offerExtra.totalPrice = extra[1];
        offer.offStage = Stage.Open;
        offers[offerID] = offer;
        offersExtra[offerID] = offerExtra;
        return finishSubmitOfferExtra(offerID);
    }

    // By specifiying the deadline of the request,
    // owner and managers can add a new request. It will have a unique identifier and others will be able to make
    // offers for it (only owner or managers can access this function).
    function submitRequest(uint deadline) public returns (uint8 status, uint requestID) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return (AccessDenied, 0);
        }
        require(msg.sender == owner() || isManager(msg.sender));
        return super.submitRequest(deadline);
    }

    // By adding the quantity of the beach chairs needed, and the intended rental date,
    // owner and managers can complete a request (only owner or managers can access this function).
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

        RequestExtra memory requestExtra;
        requestExtra.quantity = extra[0];
        requestExtra.date = extra[1];
        requestsExtra[requestID] = requestExtra;
        return finishSubmitRequestExtra(requestID);
    }

    // Manually close a request, so others won't be able to make offers for it or even see it in the list of requests.
    // In this implementation, this is completely apart from request's deadline. This can be modified based on the
    // specifications of the market we have (only owner or managers can access this function).
    function closeRequest(uint requestIdentifier) public returns (uint8 status) {
        require(requests[requestIdentifier].isDefined);
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        require(msg.sender == owner() || isManager(msg.sender));

        return super.closeRequest(requestIdentifier);
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
    function decideRequest(uint requestIdentifier, uint[] calldata acceptedOfferIDs) external returns (uint8 status) {
        require(requests[requestIdentifier].isDefined);
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        bool integrity = checkIntegrityOfAcceptedOffersList(requestIdentifier, acceptedOfferIDs);
        if(!integrity) {
            emit FunctionStatus(ImproperList);
            return ImproperList;
        }
        require(msg.sender == owner() || isManager(msg.sender));
        require(integrity);

        return _decideRequest(requestIdentifier, acceptedOfferIDs);
    }

    function deleteRequest(uint requestIdentifier) public returns (uint8 status) {
        require(requests[requestIdentifier].isDefined);
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

        return super.deleteRequest(requestIdentifier);
    }

    // Returns the type of marketplace.
    function getType() external view returns (uint8 status, string memory) {
        return (Successful, "eu.sofie-iot.offer-marketplace-demo.beach-chair");
    }

}
