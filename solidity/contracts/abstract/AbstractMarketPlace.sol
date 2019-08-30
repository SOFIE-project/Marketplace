pragma solidity ^0.5.8;

import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../interfaces/MarketPlace.sol";
import "../StatusCodes.sol";

contract AbstractMarketPlace is MarketPlace, ERC165, StatusCodes {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    enum Stage { Pending, Open, Closed }

    struct Request {
        uint ID;
        uint deadline;
        bool isDefined;
        Stage reqStage;
        bool isDecided;
        uint[] offerIDs;
        uint closingBlock;
        uint[] acceptedOfferIDs;
        address requestMaker;
    }

    struct Offer {
        uint ID;
        uint requestID;
        address offerMaker;
        bool isDefined;
        Stage offStage;
    }

    uint waitBeforeDeleteBlocks;

    uint internal reqNum;
    uint internal offNum;
    mapping (uint => Request) internal requests;
    mapping (uint => Offer) internal offers;

    uint[] internal openRequestIDs;
    uint[] internal closedRequestIDs;

    event RequestAdded(uint requestID, uint deadline);
    event RequestExtraAdded(uint requestID);
    event OfferAdded(uint offerID, uint requestID, address offerMaker);
    event OfferExtraAdded(uint offerID);

    constructor() public {
        reqNum = 1;
        offNum = 1;
        waitBeforeDeleteBlocks = 1;

        _registerInterface(_INTERFACE_ID_ERC165);
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
    }

    function getMarketInformation() external view returns (uint8 status, address ownerAddress);

    function getOpenRequestIdentifiers() external view returns (uint8 status, uint[] memory) {
        return (Successful, openRequestIDs);
    }

    function getClosedRequestIdentifiers() external view returns (uint8 status, uint[] memory) {
        return (Successful, closedRequestIDs);
    }

    function getRequest(uint requestIdentifier) external view returns (uint8 status, uint deadline, uint stage, address requestMaker) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, 0, 0, address(0));
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requests[requestIdentifier].deadline, uint(requests[requestIdentifier].reqStage), requests[requestIdentifier].requestMaker);
    }

    function getRequestOfferIDs(uint requestIdentifier) external view returns (uint8 status, uint[] memory offerIDs) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, new uint[](0));
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requests[requestIdentifier].offerIDs);
    }

    function isOfferDefined(uint offerIdentifier) external view returns (uint8 status, bool) {
        return (Successful, offers[offerIdentifier].isDefined);
    }

    function getOffer(uint offerIdentifier) external view returns (uint8 status, uint requestID, address offerMaker, uint stage) {
        if(!offers[offerIdentifier].isDefined) {
            return (UndefinedID, 0, address(0), 0);
        }
        require(offers[offerIdentifier].isDefined);

        return (Successful, offers[offerIdentifier].requestID, offers[offerIdentifier].offerMaker, uint(offers[offerIdentifier].offStage));
    }

    function submitOffer(uint requestID) public returns (uint8 status, uint offerID) {
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

    function isRequestDefined(uint requestIdentifier) external view returns (uint8 status, bool) {
        return (Successful, requests[requestIdentifier].isDefined);
    }

    function isRequestDecided(uint requestIdentifier) external view returns (uint8 status, bool) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, false);
        }
        require(requests[requestIdentifier].isDefined);

        return (Successful, requests[requestIdentifier].isDecided);
    }

    function getRequestDecision(uint requestIdentifier) public view returns (uint8 status, uint[] memory acceptedOfferIDs) {
        if(!requests[requestIdentifier].isDefined) {
            return (UndefinedID, new uint[](0));
        }
        if(!requests[requestIdentifier].isDecided) {
            return (ReqNotDecided, new uint[](0));
        }
        require(requests[requestIdentifier].isDefined && requests[requestIdentifier].isDecided);

        return (Successful, requests[requestIdentifier].acceptedOfferIDs);
    }

    function finishSubmitOfferExtra(uint offerID) internal returns (uint8 status, uint offID) {
        emit FunctionStatus(Successful);
        emit OfferExtraAdded(offerID);
        return (Successful, offerID);
    }
}