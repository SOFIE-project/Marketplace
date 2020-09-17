pragma solidity ^0.5.8;

import "../abstract/AbstractOwnerManagerMarketPlace.sol";
import "../interfaces/ArrayExtraData.sol";

contract DemoMarketPlace is AbstractOwnerManagerMarketPlace, ArrayRequestExtraData, ArrayOfferExtraData {
    struct RequestExtra {
        uint quantity;
        uint variety;
    }

    struct OfferExtra {
        uint price;
        uint minQuantity;
        uint maxQuantity;
    }

    mapping (uint => RequestExtra) internal requestsExtra;
    mapping (uint => OfferExtra) internal offersExtra;

    constructor() public {
        _registerInterface(this.submitOfferArrayExtra.selector
                            ^ this.submitRequestArrayExtra.selector);
    }

    function getRequestExtra(uint requestIdentifier) public view returns (uint8 status, uint quantity, uint variety) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, 0, 0);
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requestsExtra[requestIdentifier].quantity, requestsExtra[requestIdentifier].variety);
    }

    function getOfferExtra(uint offerIdentifier) public view returns (uint8 status, uint price, uint minQuantity, uint maxQuantity) {
        if(!offers[offerIdentifier].isDefined) {
            return (UndefinedID, 0, 0, 0);
        }
        require(offers[offerIdentifier].isDefined);

        return (Successful, offersExtra[offerIdentifier].price, offersExtra[offerIdentifier].minQuantity, offersExtra[offerIdentifier].maxQuantity);
    }

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
        if (!(extra[1] > 0 && extra[2] <= requestsExtra[offer.requestID].quantity)) {
            emit FunctionStatus(InvalidInput);
            return(InvalidInput, 0);
        }
        require(offer.isDefined && offer.offStage == Stage.Pending
            && offer.offerMaker == msg.sender
            && requests[offer.requestID].reqStage == Stage.Open);
        require(extra[1] > 0 && extra[2] <= requestsExtra[offer.requestID].quantity);

        OfferExtra memory offerExtra;
        offerExtra.price = extra[0];
        offerExtra.minQuantity = extra[1];
        offerExtra.maxQuantity = extra[2];
        offer.offStage = Stage.Open;
        offers[offerID] = offer;
        offersExtra[offerID] = offerExtra;
        return finishSubmitOfferExtra(offerID);
    }

    function submitRequest(uint deadline) public returns (uint8 status, uint requestID) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return (AccessDenied, 0);
        }
        require(msg.sender == owner() || isManager(msg.sender));

        return super.submitRequest(deadline);
    }

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
        requestExtra.variety = extra[1];
        requestsExtra[requestID] = requestExtra;
        return finishSubmitRequestExtra(requestID);
    }

    function decideRequest(uint requestIdentifier, uint[] calldata acceptedOfferIDs) external returns (uint8 status) {
        if(!(msg.sender == owner() || isManager(msg.sender))) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        require(msg.sender == owner() || isManager(msg.sender));

        return _decideRequest(requestIdentifier, acceptedOfferIDs);
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

        return super.deleteRequest(requestIdentifier);
    }

    function getType() external view returns (uint8 status, string memory) {
        return (Successful, "eu.sofie-iot.offer-marketplace-demo.demo");
    }
}
