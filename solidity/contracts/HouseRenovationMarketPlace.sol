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

contract HouseDecorationMarketPlace is AbstractOwnerManagerMarketPlace, ArrayExtraData {
    enum RoomType {LivingRoom, Bedroom, Kitchen, Bathroom}

    struct RequestExtra {
        uint quantity;
        RoomType roomType;
        uint priceLimit;
        uint priceTarget;
    }

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
    function getRequestExtra(uint requestIdentifier) public view returns (uint8 status, uint quantity, RoomType roomType, uint priceLimit, uint priceTarget) {
        // request undefined
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, 0, RoomType(0), 0, 0);
        }
        // fetch requestExtra
        RequestExtra memory requestExtra = requestsExtra[requestIdentifier];
        return (Successful, requestExtra.quantity, requestExtra.roomType, requestExtra.priceLimit, requestExtra.priceTarget);
    }

    // Get specific details of an offer.
    function getOfferExtra(uint offerIdentifier) public view returns (uint8 status, uint price) {
        // offer undefined
        if(!offers[offerIdentifier].isDefined) {
            return (UndefinedID, 0);
        }
        OfferExtra memory offerExtra = offersExtra[offerIdentifier];
        return (Successful, offerExtra.price);
    }

    // By sending the identifier of a request, agencies can make offer to compete for the house decoration contract.
    function submitOffer(uint requestID) public returns (uint8 status, uint offerID) {
        // request undefined
        if(!requests[requestID].isDefined) {
            emit FunctionStatus(UndefinedID);
            return (UndefinedID, 0);
        }
        // deadline passed
        if(now > requests[requestID].deadline) {
            emit FunctionStatus(DeadlinePassed);
            return (DeadlinePassed, 0);
        }
        // request not open
        if(requests[requestID].reqStage != Stage.Open) {
            emit FunctionStatus(RequestNotOpen);
            return (RequestNotOpen, 0);
        }
        return super.submitOffer(requestID);
    }

    // By sending the proposed price, agencies can complete and open their offer to compete for the house decoration contract.
    // (only the initial offer maker can access this function).
    function submitOfferArrayExtra(uint offerID, uint[] calldata extra) external returns (uint8 status, uint offID) {
        Offer memory offer = offers[offerID];
        // offer undefined
        if(!offer.isDefined) {
            emit FunctionStatus(UndefinedID);
            return (UndefinedID, 0);
        }
        // offer is not pending
        if(offer.offStage != Stage.Pending) {
            emit FunctionStatus(NotPending);
            return (NotPending, 0);
        }
        // access is limited to offer maker only
        if(offer.offerMaker != msg.sender) {
            emit FunctionStatus(AccessDenied);
            return (AccessDenied, 0);
        }
        // request is not open
        if(requests[offer.requestID].reqStage != Stage.Open) {
            emit FunctionStatus(RequestNotOpen);
            return (RequestNotOpen, 0);
        }

        OfferExtra memory offerExtra;
        offerExtra.price = extra[0];
        offer.offStage = Stage.Open;
        // update offers and offersExtra
        offers[offerID] = offer;
        offersExtra[offerID] = offerExtra;
        return finishSubmitOfferExtra(offerID);
    }

    // By specifiying the deadline of the request, owner and managers
    // can add a new request. It will have a unique identifier and others will be able to make offers for it
    // (only owner or managers can access this function).
    function submitRequest(uint deadline) public returns (uint8 status, uint requestID) {
        // not owner of managers
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return (AccessDenied, 0);
        }
        return super.submitRequest(deadline);
    }

    // By specifiying the type of the roms with quantity, owner and managers
    // can complete a request (only owner or managers can access this function).
    function submitRequestArrayExtra(uint requestID, uint[] calldata extra) external returns (uint8 status, uint reqID) {
        // not owner or managers
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return (AccessDenied, 0);
        }
        // request undefined
        if(!requests[requestID].isDefined) {
            emit FunctionStatus(UndefinedID);
            return (UndefinedID, 0);
        }
        // request not pending
        if(requests[requestID].reqStage != Stage.Pending) {
            emit FunctionStatus(NotPending);
            return (NotPending, 0);
        }

        RequestExtra memory requestExtra;
        requestExtra.quantity = extra[0];
        requestExtra.roomType = RoomType(extra[1]);
        requestExtra.priceLimit = extra[2];
        requestExtra.priceTarget = extra[3];
        // update requestsExtra
        requestsExtra[requestID] = requestExtra;
        return finishSubmitRequestExtra(requestID); // this opens the request and updates the requests
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

        uint minOffer = requestsExtra[requestIdentifier].priceLimit;
        uint limit = requestsExtra[requestIdentifier].priceLimit;
        uint target = requestsExtra[requestIdentifier].priceTarget;

        uint[] memory acceptedOfferIDs = new uint[](1);
        for (uint i = 0; i < requests[requestIdentifier].offerIDs.length; i++) {
            Offer memory offer = offers[requests[requestIdentifier].offerIDs[i]];
            OfferExtra memory offerExtra = offersExtra[requests[requestIdentifier].offerIDs[i]];
            if (offer.offStage == Stage.Open && offerExtra.price <= target) {
              acceptedOfferIDs[0] = requests[requestIdentifier].offerIDs[i];
              return _decideRequest(requestIdentifier, acceptedOfferIDs);
            }
            if (offer.offStage == Stage.Open && offerExtra.price > limit) {
              continue;
            }
            if (offer.offStage == Stage.Open && offerExtra.price < minOffer) {
                minOffer = offerExtra.price;
                acceptedOfferIDs[0] = requests[requestIdentifier].offerIDs[i];
            }
        }
        if (acceptedOfferIDs[0] == 0) {
          return Fail;
        }
        return _decideRequest(requestIdentifier, acceptedOfferIDs);
    }

    function deleteRequest(uint requestIdentifier) public returns (uint8 status) {
        require(requests[requestIdentifier].isDefined);
        // not owner or managers
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        // request not closed
        if(requests[requestIdentifier].reqStage != Stage.Closed) {
            emit FunctionStatus(ReqNotClosed);
            return ReqNotClosed;
        }
        // waiting for closing
        if(requests[requestIdentifier].closingBlock + waitBeforeDeleteBlocks > block.number) {
            emit FunctionStatus(NotTimeForDeletion);
            return NotTimeForDeletion;
        }

        return super.deleteRequest(requestIdentifier);
    }

    // Returns the type of marketplace.
    function getType() external view returns (uint8 status, string memory) {
        return (Successful, "eu.sofie-iot.offer-marketplace-demo.house-renovation");
    }

}
