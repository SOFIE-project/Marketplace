pragma solidity ^0.5.8;

import "./DemoMarketPlace.sol";

contract PopulatedDemoMarketPlace is DemoMarketPlace {

    function stepOne() public {
        uint8 status;
        uint reqId;
        uint offId;
        uint[] memory acceptedOfferIDs = new uint[](1);
        RequestExtra memory requestExtra;
        OfferExtra memory offerExtra;
        Offer memory offer;
        /* 1 decided request with 3 offers, of which 1 is selected */
        (status, reqId) = submitRequest(100);
        requestExtra.quantity = 5;
        requestExtra.variety = 1;
        requestsExtra[reqId] = requestExtra;
        finishSubmitRequestExtra(reqId);

        (status, offId) = AbstractMarketPlace.submitOffer(reqId);
        offer = offers[offId];
        offerExtra.price = 15;
        offerExtra.minQuantity = 1;
        offerExtra.maxQuantity = 2;
        offer.offStage = Stage.Open;
        offer.offerMaker = address(0x01);
        offers[offId] = offer;
        offersExtra[offId] = offerExtra;
        finishSubmitOfferExtra(offId);

        (status, offId) = AbstractMarketPlace.submitOffer(reqId);
        offer = offers[offId];
        offerExtra.price = 10;
        offerExtra.minQuantity = 2;
        offerExtra.maxQuantity = 3;
        offer.offStage = Stage.Open;
        offer.offerMaker = address(0x02);
        offers[offId] = offer;
        offersExtra[offId] = offerExtra;
        finishSubmitOfferExtra(offId);

        (status, offId) = AbstractMarketPlace.submitOffer(reqId);
        offer = offers[offId];
        offerExtra.price = 20;
        offerExtra.minQuantity = 1;
        offerExtra.maxQuantity = 3;
        offer.offStage = Stage.Open;
        offer.offerMaker = address(0x03);
        offers[offId] = offer;
        offersExtra[offId] = offerExtra;
        finishSubmitOfferExtra(offId);

        acceptedOfferIDs[0] = offId;
        _decideRequest(reqId, acceptedOfferIDs);
    }

    function stepTwo() public {
        uint8 status;
        uint reqId;
        uint offId;
        RequestExtra memory requestExtra;
        OfferExtra memory offerExtra;
        Offer memory offer;       /* 1 closed request (e.g. deadline exceeded) with 3 offers, but not decided yet */
        (status, reqId) = submitRequest(100);
        requestExtra.quantity = 5;
        requestExtra.variety = 2;
        requestsExtra[reqId] = requestExtra;
        finishSubmitRequestExtra(reqId);

        (status, offId) = AbstractMarketPlace.submitOffer(reqId);
        offer = offers[offId];
        offerExtra.price = 12;
        offerExtra.minQuantity = 3;
        offerExtra.maxQuantity = 4;
        offer.offStage = Stage.Open;
        offer.offerMaker = address(0x04);
        offers[offId] = offer;
        offersExtra[offId] = offerExtra;
        finishSubmitOfferExtra(offId);

        (status, offId) = AbstractMarketPlace.submitOffer(reqId);
        offer = offers[offId];
        offerExtra.price = 10;
        offerExtra.minQuantity = 4;
        offerExtra.maxQuantity = 5;
        offer.offStage = Stage.Open;
        offer.offerMaker = address(0x05);
        offers[offId] = offer;
        offersExtra[offId] = offerExtra;
        finishSubmitOfferExtra(offId);

        (status, offId) = AbstractMarketPlace.submitOffer(reqId);
        offer = offers[offId];
        offerExtra.price = 20;
        offerExtra.minQuantity = 1;
        offerExtra.maxQuantity = 5;
        offer.offStage = Stage.Open;
        offer.offerMaker = address(0x06);
        offers[offId] = offer;
        offersExtra[offId] = offerExtra;
        finishSubmitOfferExtra(offId);
        closeRequest(reqId);
    }

    function stepThree() public {
        uint8 status;
        uint reqId;
        RequestExtra memory requestExtra;
        /* 1 open request without any offers */
        (status, reqId) = submitRequest(100);
        requestExtra.quantity = 7;
        requestExtra.variety = 3;
        requestsExtra[reqId] = requestExtra;
        finishSubmitRequestExtra(reqId);
    } 
}