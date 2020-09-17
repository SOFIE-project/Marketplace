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

contract FlowerMarketPlace is AbstractOwnerManagerMarketPlace, ArrayRequestExtraData, ArrayOfferExtraData {

    enum FlowerType {Rose, Tulip, Jasmine, White}

    struct RequestExtra {
        uint quantity;
        FlowerType flowerType;
    }

    // Minimum and maximum length of extra elements for an offer extra submission
    uint constant private minimumNumberOfRequestExtraElements = 2;
    uint constant private maximumNumberOfRequestExtraElements = 2;

    // Minimum and maximum length of extra elements for an offer extra submission
    uint constant private minimumNumberOfOfferExtraElements = 1;
    uint constant private maximumNumberOfOfferExtraElements = 1;

    struct OfferExtra {
        uint price;
    }

    mapping (uint => RequestExtra) private requestsExtra;
    mapping (uint => OfferExtra) private offersExtra;

    constructor() public {
        _registerInterface(this.submitOfferArrayExtra.selector
                            ^ this.submitRequestArrayExtra.selector);
    }

    // Get the specific stipulations of a request.
    function getRequestExtra(uint requestIdentifier) public view returns (uint8 status, uint quantity, FlowerType flowerType) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, 0, FlowerType(0));
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requestsExtra[requestIdentifier].quantity, requestsExtra[requestIdentifier].flowerType);
    }

    // Get specific details of an offer.
    function getOfferExtra(uint offerIdentifier) public view returns (uint8 status, uint price) {
        if(!offers[offerIdentifier].isDefined) {
            return (UndefinedID, 0);
        }
        require(offers[offerIdentifier].isDefined);

        return (Successful, offersExtra[offerIdentifier].price);
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

        return super.submitOffer(requestID);
    }

    // By sending the proposed price, others can complete and open their offer to buy flowers.
    // (only the initial offer maker can access this function).
    function submitOfferArrayExtra(uint offerID, uint[] calldata extra) external payable returns (uint8 status, uint offID) {
        require(
            extra.length >= minimumNumberOfOfferExtraElements && extra.length <= maximumNumberOfOfferExtraElements
        );

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
        offerExtra.price = extra[0];
        offer.offStage = Stage.Open;
        offers[offerID] = offer;
        offersExtra[offerID] = offerExtra;
        return finishSubmitOfferExtra(offerID);
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

        return super.submitRequest(deadline);
    }

    // By specifiying the type of the flowers, quantity of them, owner and managers
    // can complete a request (only owner or managers can access this function).
    function submitRequestArrayExtra(uint requestID, uint[] calldata extra) external returns (uint8 status, uint reqID) {
        if (extra.length < minimumNumberOfRequestExtraElements || extra.length > maximumNumberOfRequestExtraElements) {
            emit FunctionStatus(InvalidInput);
            return (InvalidInput, 0);
        }

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
        requestExtra.flowerType = FlowerType(extra[1]);
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

    // Choose which offer to accept, based on the proposed prices. The decision process can differ for other markets,
    // and it can be very complicated. Even in some cases, the decision must be made in the backend.
    // (only owner or managers can access this function).
    function decideRequest(uint requestIdentifier, uint[] calldata /*acceptedOfferIDs*/) external returns (uint8 status) {
        require(requests[requestIdentifier].isDefined);
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        require(msg.sender == owner() || isManager(msg.sender));

        uint maxOffer = 0;
        uint[] memory acceptedOfferIDs = new uint[](1);
        for (uint i = 0; i < requests[requestIdentifier].offerIDs.length; i++) {
            Offer memory offer = offers[requests[requestIdentifier].offerIDs[i]];
            OfferExtra memory offerExtra = offersExtra[requests[requestIdentifier].offerIDs[i]];
            if (offer.offStage == Stage.Open && maxOffer < offerExtra.price) {
                maxOffer = offerExtra.price;
                acceptedOfferIDs[0] = requests[requestIdentifier].offerIDs[i];
            }
        }
        return _decideRequest(requestIdentifier, acceptedOfferIDs);
    }

    function getOffer(uint offerIdentifier) public view returns (uint8 status, uint requestID, address offerMaker, uint stage) {
        if(!offers[offerIdentifier].isDefined) {
            return (UndefinedID, 0, address(0), 0);
        }
        require(offers[offerIdentifier].isDefined);
        return (Successful, offers[offerIdentifier].requestID, offers[offerIdentifier].offerMaker, uint(offers[offerIdentifier].offStage));
    }

    function settleTrade(uint requestID, uint offerID) public returns (uint8 status) {
        (, uint reqID, address offerMaker,) = getOffer(offerID);
        require(reqID == requestID && msg.sender == offerMaker);

        super.settleTrade(requestID, offerID);
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
        return (Successful, "eu.sofie-iot.offer-marketplace-demo.flower");
    }

}
