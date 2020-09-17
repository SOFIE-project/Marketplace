// jshint esversion: 8

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

var HouseDecorationMarketPlace = artifacts.require("HouseDecorationMarketPlace");

contract('HouseDecorationMarketPlace', function (accounts) {

    it("testing owner & managers", async () => {
        let market = await HouseDecorationMarketPlace.deployed();
        let {status, ownerAddress} = await market.getMarketInformation();
        assert.equal(status.toNumber(), 0, "status wasn't successful");
        assert.equal(ownerAddress, accounts[0], "acconts[0] wasn't the initial owner");
        await market.addManager(accounts[1]);
        await market.addManager(accounts[2]);
        await market.addManager(accounts[0]);
        let res1 = await market.addManager(accounts[0]);
        assert.equal(res1.logs[0].args.status.toNumber(), 11, "status should've been duplicate manager");
        let tx = await market.addManager(accounts[3]);
        assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        await market.revokeManagerCert(accounts[1]);
        await market.revokeManagerCert(accounts[3]);
        res1 = await market.revokeManagerCert(accounts[3], {from: accounts[3]});
        assert.equal(res1.logs[0].args.status.toNumber(), 1, "status should've been access denied");
        await market.addManager(accounts[1]);
        res1 = await market.changeOwner(accounts[3], {from: accounts[6]});
        assert.equal(res1.logs[0].args.status.toNumber(), 1, "status should've been access denied");
        tx = await market.changeOwner(accounts[3]);
        assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let {ownerAddress: ownerAddress1} = await market.getMarketInformation();
        assert.equal(ownerAddress1, accounts[3], "acconts[3] wasn't the owner");
        await market.changeOwner(accounts[0], {from: accounts[3]});
        let {ownerAddress: ownerAddress2} = await market.getMarketInformation();
        assert.equal(ownerAddress2, accounts[0], "acconts[0] wasn't the owner");
    });

    it("testing requests & offers", async () => {
        let market = await HouseDecorationMarketPlace.deployed();
        let tx1 = await market.submitRequest(2000000000);
        assert.equal(tx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        assert.equal(tx1.logs[1].args.requestID.toNumber(), 1, "requestID wasn't 1");
        assert.equal(tx1.logs[1].args.deadline.toNumber(), 2000000000, "quantity wasn't 2000000000");
        let {requestMaker: requestMaker} = await market.getRequest(tx1.logs[1].args.requestID.toNumber());
        assert.equal(requestMaker, accounts[0], "request maker was not accounts[0]");
        let txx = await market.submitRequestArrayExtra(tx1.logs[1].args.requestID, [20, 3, 500, 100]);
        assert.equal(txx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        assert.equal(txx.logs[1].args.requestID.toNumber(), 1, "requestID wasn't 1");
        let {quantity, roomType, priceLimit, priceTarget} = await market.getRequestExtra(txx.logs[1].args.requestID.toNumber());
        assert.equal(quantity.toNumber(), 20, "quantity wasn't 20");
        assert.equal(roomType.toNumber(), 3, "roomType wasn't 3 (Bathroom)");
        assert.equal(priceLimit.toNumber(), 500, "priceLimit wasn't 500");
        assert.equal(priceTarget.toNumber(), 100, "priceTarget wasn't 100");
        let tx2 = await market.submitRequest(2000000000);
        await market.submitRequestArrayExtra(tx2.logs[1].args.requestID, [45, 0, 600, 200]);
        let tx3 = await market.submitRequest(2000000000);
        await market.submitRequestArrayExtra(tx3.logs[1].args.requestID, [100, 2, 700, 300]);
        let txx1 = await market.closeRequest(2);
        assert.equal(txx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let {status, '1': openReqs} = await market.getOpenRequestIdentifiers();
        assert.equal(status.toNumber(), 0, "status wasn't successful");
        assert.equal(openReqs[0].toNumber(), 1, "openReqs[0] wasn't 1");
        assert.equal(openReqs[1].toNumber(), 3, "openReqs[1] wasn't 3");

        tx3 = await market.submitRequest(2000000000);
        await market.submitRequestArrayExtra(tx3.logs[1].args.requestID, [80, 1, 800, 400]);

        let {status: status1, '1': isDef1} = await market.isRequestDefined(2);
        assert.equal(status1.toNumber(), 0, "status wasn't successful");
        assert.equal(isDef1, true, "request#2 wasn't defined");
        let {status: status2, '1': isDef2} = await market.isRequestDefined(8);
        assert.equal(status2.toNumber(), 0, "status wasn't successful");
        assert.equal(isDef2, false, "request#8 was defined!!!");
        let {status: status3, deadline: deadline3, stage: stage3} = await market.getRequest(3);
        assert.equal(status3.toNumber(), 0, "status wasn't successful");
        assert.equal(deadline3.toNumber(), 2000000000, "req3 deadline wasn't 2000000000");
        assert.equal(stage3.toNumber(), 1, "req3 wasn't open");
        let {status: statusx3, quantity: quantityx3, roomType: roomTypex3, priceLimit: priceLimit3, priceTarget: priceTarget3} = await market.getRequestExtra(3);
        assert.equal(statusx3.toNumber(), 0, "status wasn't successful");
        assert.equal(quantityx3.toNumber(), 100, "req3 quantity wasn't 100");
        assert.equal(roomTypex3.toNumber(), 2, "req3 flowerType wasn't 2");
        assert.equal(priceLimit3.toNumber(), 700, "priceLimit wasn't 700");
        assert.equal(priceTarget3.toNumber(), 300, "priceTarget wasn't 300");
        tx1 = await market.submitOffer(3, {from: accounts[6]});
        assert.equal(tx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        assert.equal(tx1.logs[1].args.offerID.toNumber(), 1, "offerID wasn't 1");
        assert.equal(tx1.logs[1].args.requestID.toNumber(), 3, "requestID wasn't 3");
        assert.equal(tx1.logs[1].args.offerMaker, accounts[6], "offerMaker wasn't accounts[6]");
        txx = await market.submitOfferArrayExtra(tx1.logs[1].args.offerID, [200], {from: accounts[6]});
        assert.equal(txx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        assert.equal(txx.logs[1].args.offerID.toNumber(), 1, "offerID wasn't 1");
        let {price} = await market.getOfferExtra(txx.logs[1].args.offerID.toNumber());
        assert.equal(price.toNumber(), 200, "price wasn't 200");
        tx2 = await market.submitOffer(3, {from: accounts[8]});
        await market.submitOfferArrayExtra(tx2.logs[1].args.offerID, [130], {from: accounts[8]});


        tx3 = await market.submitOffer(1, {from: accounts[2]});
        await market.submitOfferArrayExtra(tx3.logs[1].args.offerID, [666], {from: accounts[2]});
        let tx4 = await market.submitOffer(1);
        await market.submitOfferArrayExtra(tx4.logs[1].args.offerID, [750]);
        let tx5 = await market.submitOffer(4);
        await market.submitOfferArrayExtra(tx5.logs[1].args.offerID, [600]);
        let tx6 = await market.submitOffer(4);

        let res = await market.submitOfferArrayExtra(tx6.logs[1].args.offerID, [780], {from: accounts[5]});
        assert.equal(res.logs[0].args.status.toNumber(), 1, "status should've been access denied");
        await market.submitOfferArrayExtra(tx6.logs[1].args.offerID, [780]);

        let {status: statusOdef1, '1': isOdef1} = await market.isOfferDefined(2);
        assert.equal(statusOdef1.toNumber(), 0, "status wasn't successful");
        assert.ok(isOdef1, "offer #2 wasn't defined");
        let {status: statusOdef2, '1': isOdef2} = await market.isOfferDefined(22);
        assert.equal(statusOdef2.toNumber(), 0, "status wasn't successful");
        assert.equal(isOdef2, false, "offer #22 was defined");
        let {status: statusOff2, requestID: requestIDOff2, offerMaker: offerMakerOff2, stage: stageOff2} =
            await market.getOffer(2);
        assert.equal(statusOff2.toNumber(), 0, "status wasn't successful");
        assert.equal(requestIDOff2.toNumber(), 3, "off2 requestID wasn't 3");
        assert.equal(offerMakerOff2, accounts[8], "off2 offerMaker wasn't accounts[8]");
        assert.equal(stageOff2.toNumber(), 1, "off2 wasn't open");
        let {status: statusExt2, price: priceExt2} = await market.getOfferExtra(2);
        assert.equal(statusExt2.toNumber(), 0, "status wasn't successful");
        assert.equal(priceExt2.toNumber(), 130, "off2 price wasn't 130");
        let {status: statusOffIDs, offerIDs: offIDs} = await market.getRequestOfferIDs(3, {from: accounts[1]});
        assert.equal(statusOffIDs.toNumber(), 0, "status wasn't successful");
        assert.equal(offIDs[0].toNumber(), 1, "offIDs[0] wasn't 1");
        assert.equal(offIDs[1].toNumber(), 2, "offIDs[1] wasn't 2");


        let {status: statusOffIDs1, offerIDs: offIDs1} = await market.getRequestOfferIDs(1, {from: accounts[0]});
        assert.equal(statusOffIDs1.toNumber(), 0, "status wasn't successful");
        assert.equal(offIDs1[0].toNumber(), 3, "offIDs[0] wasn't 1");
        assert.equal(offIDs1[1].toNumber(), 4, "offIDs[1] wasn't 2");
        
        await market.decideRequest(1, []);
        let {status: statusIsDec1, '1': isDec1} = await market.isRequestDecided(1);
        assert.equal(statusIsDec1.toNumber(), 0, "status wasn't successful");
        assert.equal(isDec1, false, "request#1 was decided");
        let {status: statusAcc1, acceptedOfferIDs: accOffIDs1} = await market.getRequestDecision(4);
        assert.equal(statusAcc1.toNumber(), 6, "status should've been request not decided");

        await market.decideRequest(3, []);
        let {status: statusIsDec3, '1': isDec3} = await market.isRequestDecided(3);
        assert.equal(statusIsDec3.toNumber(), 0, "status wasn't successful");
        assert.equal(isDec3, true, "request#3 wasn't decided");
        let {status: statusAcc3, acceptedOfferIDs: accOffIDs3} = await market.getRequestDecision(3);
        assert.equal(statusAcc3.toNumber(), 0, "status wasn't successful");
        assert.equal(accOffIDs3[0].toNumber(), 1, "accepted offer ID wasn't 1 (200)");

        
        await market.decideRequest(4, []);
        let {status: statusAcc4, acceptedOfferIDs: accOffIDs4} = await market.getRequestDecision(4);
        assert.equal(statusAcc4.toNumber(), 0, "status wasn't successful");
        assert.equal(accOffIDs4[0].toNumber(), 5, "accepted offer ID wasn't 5 (600)");


        let {status: statusIsDec2, '1': isDec2} = await market.isRequestDecided(2);
        assert.equal(statusIsDec2.toNumber(), 0, "status wasn't successful");
        assert.equal(isDec2, false, "request#2 was decided!!!");
        
        let {status: statusClosedReqs1, '1': closedReqs1} = await market.getClosedRequestIdentifiers();
        assert.equal(statusClosedReqs1.toNumber(), 0, "status wasn't successful");
        assert.equal(closedReqs1[0].toNumber(), 2, "closedReqs[0] wasn't 2");
        assert.equal(closedReqs1[1].toNumber(), 3, "closedReqs[1] wasn't 3");
        assert.equal(closedReqs1[2].toNumber(), 4, "closedReqs[1] wasn't 4");
        let tx = await market.deleteRequest(2);
        assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let {status: statusClosedReqs2, '1': closedReqs2} = await market.getClosedRequestIdentifiers();
        assert.equal(statusClosedReqs2.toNumber(), 0, "status wasn't successful");
        assert.equal(closedReqs2[0].toNumber(), 3, "closedReqs[0] wasn't 3");
        assert.equal(closedReqs2[1].toNumber(), 4, "closedReqs[1] wasn't 4");
    });

   
    it("testing status codes", async () => {
        let market = await HouseDecorationMarketPlace.deployed();
        let res1 = await market.addManager(accounts[7], {from: accounts[9]});
        assert.equal(res1.logs[0].args.status.toNumber(), 1, "status should've been access denied");
        let res2 = await market.getRequest(56);
        assert.equal(res2[0].toNumber(), 2, "status should've been undefinedID");         
        let res3 = await market.submitRequest(50);
        let res4 = await market.submitOffer(res3.logs[1].args.requestID);
        assert.equal(res4.logs[0].args.status.toNumber(), 3, "status should've been deadline passed");
        let res5 = await market.submitRequest(2000000000);
        let res6 = await market.submitOffer(res5.logs[1].args.requestID);
        assert.equal(res6.logs[0].args.status.toNumber(), 4, "status should've been request not open");
        let res7 = await market.submitOffer(1);
        let res8 = await market.submitOfferArrayExtra(res7.logs[1].args.offerID.toNumber(), [252]);
        assert.equal(res8.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let res9 = await market.submitOfferArrayExtra(res8.logs[1].args.offerID.toNumber(), [254]);
        assert.equal(res9.logs[0].args.status.toNumber(), 5, "status should've been not pending");
        let res10 = await market.getRequestDecision(1);
        assert.equal(res10[0], 6, "status should've been request not decided");
        let res11 = await market.deleteRequest(1);
        assert.equal(res11.logs[0].args.status.toNumber(), 7, "status should've been request not closed");
        let res12 = await market.submitRequest(80, {from: accounts[9]});
        assert.equal(res12.logs[0].args.status.toNumber(), 1, "status should've been access denied");
        let res13 = await market.submitRequest(200000);
        let res14 = await market.submitRequestArrayExtra(res13.logs[1].args.requestID, [45, 0, 600, 200], {from: accounts[9]});
        assert.equal(res14.logs[0].args.status.toNumber(), 1, "status should've been access denied");
        let res15 = await market.submitRequestArrayExtra(res13.logs[1].args.requestID + 10, [45, 0, 600, 200]);
        assert.equal(res15.logs[0].args.status.toNumber(), 2, "status should've been undefined ID");
        let res17 = await market.closeRequest(res13.logs[1].args.requestID, {from: accounts[9]});
        assert.equal(res17.logs[0].args.status.toNumber(), 1, "status should've been access denied");
        await market.closeRequest(res13.logs[1].args.requestID);
        let res18 = await market.submitRequestArrayExtra(res13.logs[1].args.requestID, [45, 0, 600, 200]);
        assert.equal(res18.logs[0].args.status.toNumber(), 5, "status should've been not pending");
        let res19 = await market.submitOffer(res13.logs[1].args.requestID + 10);
        assert.equal(res19.logs[0].args.status.toNumber(), 2, "status should've been request not defined");
        let res20 = await market.submitOfferArrayExtra(res7.logs[1].args.offerID.toNumber() + 10, [252]);
        assert.equal(res20.logs[0].args.status.toNumber(), 2, "status should've been offer not defined");
        
        let res21 = await market.submitRequest(2000000000);
        let res22 = await market.submitRequestArrayExtra(res21.logs[1].args.requestID, [45, 0, 600, 200]);
        assert.equal(res22.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let res23 = await market.submitOffer(res21.logs[1].args.requestID);
        await market.closeRequest(res21.logs[1].args.requestID);
        let res24 = await market.submitOfferArrayExtra(res23.logs[1].args.offerID.toNumber(), [254] );
        assert.equal(res24.logs[0].args.status.toNumber(), 4, "status should've been request not open");

        let res25 = await market.deleteRequest(1, {from: accounts[9]});
        assert.equal(res25.logs[0].args.status.toNumber(), 1, "status should've been access denied");

        let {status} = await market.getOffer(res23.logs[1].args.offerID.toNumber() + 1);
        assert.equal(status.toNumber(), 2, "status should've been offer not defined");
        let {status: statusExt} = await market.getOfferExtra(res23.logs[1].args.offerID.toNumber() + 1);
        assert.equal(statusExt.toNumber(), 2, "status should've been offer not defined");
        let {status:statusExt2} = await market.getRequestExtra(2);
        assert.equal(statusExt2.toNumber(), 2, "status should've been request not defined");
        let {status: statusOffIDs1} = await market.getRequestOfferIDs(2);
        assert.equal(statusOffIDs1.toNumber(), 2, "status should've been request not defined");
        let {status: statusIsDec1} = await market.isRequestDecided(2);
        assert.equal(statusIsDec1.toNumber(), 2, "status should've been request not defined");
        let {status: statusDec2} = await market.getRequestDecision(2);
        assert.equal(statusDec2.toNumber(), 2, "status should've been request not defined");
    });
    
    it("testing ERC165 interface support", async () => {
        let market = await HouseDecorationMarketPlace.deployed();
        let erc165Selector = web3.eth.abi.encodeFunctionSignature('supportsInterface(bytes4)');
        let res = await market.supportsInterface(web3.utils.hexToBytes(erc165Selector));
        assert.equal(res, true, "contract does not support ERC165");
    });

     
    it("testing MultiManager interface support", async () => {
        let market = await HouseDecorationMarketPlace.deployed();
        let interfaceFunctions = [
            'changeOwner(address)',
            'addManager(address)',
            'revokeManagerCert(address)'
        ];

        let interfaceId = interfaceFunctions.map(web3.eth.abi.encodeFunctionSignature).map((x) => parseInt(x, 16)).reduce((x, y) => x ^ y);

        interfaceId = interfaceId > 0 ? interfaceId : 0xFFFFFFFF + interfaceId + 1;
        interfaceId = '0x' + interfaceId.toString(16);
        let res = await market.supportsInterface(web3.utils.hexToBytes(interfaceId));
        assert.equal(res, true, "contract does not support MultiManager interface");
    });
    
    // it('testing MarketPlace interface support', async () => {
    //     let market = await HouseDecorationMarketPlace.deployed();
    //     let interfaceFunctions = [
    //         'getMarketInformation()',
    //         'getOpenRequestIdentifiers()',
    //         'getClosedRequestIdentifiers()',
    //         'getRequest(uint256)',
    //         'getRequestOfferIDs(uint256)',
    //         'isOfferDefined(uint256)',
    //         'getOffer(uint256)',
    //         'submitOffer(uint256)',
    //         'isRequestDefined(uint256)',
    //         'isRequestDecided(uint256)',
    //         'getRequestDecision(uint256)'
    //     ];

    //     let interfaceId = interfaceFunctions.map(web3.eth.abi.encodeFunctionSignature).map((x) => parseInt(x, 16)).reduce((x, y) => x ^ y);

    //     interfaceId = interfaceId > 0 ? interfaceId : 0xFFFFFFFF + interfaceId + 1;
    //     interfaceId = '0x' + interfaceId.toString(16);
    //     let res = await market.supportsInterface(web3.utils.hexToBytes(interfaceId));
    //     assert.equal(res, true, "contract does not support MarketPlace interface");
    // });

    it("testing ManageableMarketPlace interface support", function (done) {
        var market;
        HouseDecorationMarketPlace.deployed().then(function (instance) {
            market = instance;
        }).then(function () {
            let interfaceFunctions = [
                'submitRequest(uint256)',
                'closeRequest(uint256)',
                'decideRequest(uint256,uint256[])',
                'deleteRequest(uint256)'
            ];

            let interfaceId = interfaceFunctions.map(web3.eth.abi.encodeFunctionSignature).map((x) => parseInt(x, 16)).reduce((x, y) => x ^ y);

            interfaceId = interfaceId > 0 ? interfaceId : 0xFFFFFFFF + interfaceId + 1;
            interfaceId = '0x' + interfaceId.toString(16);
            return market.supportsInterface(web3.utils.hexToBytes(interfaceId));
        }).then(function (res) {
            assert.equal(res, true, "contract does not support ManageableMarketPlace interface");
            done();
        });
    });

    it("testing ArrayExtraData interface support", async () => {
        let market = await HouseDecorationMarketPlace.deployed();
        let interfaceFunctions = [
            'submitOfferArrayExtra(uint256,uint256[])',
            'submitRequestArrayExtra(uint256,uint256[])'
        ];

        let interfaceId = interfaceFunctions.map(web3.eth.abi.encodeFunctionSignature).map((x) => parseInt(x, 16)).reduce((x, y) => x ^ y);

        interfaceId = interfaceId > 0 ? interfaceId : 0xFFFFFFFF + interfaceId + 1;
        interfaceId = '0x' + interfaceId.toString(16);
        let res = await market.supportsInterface(web3.utils.hexToBytes(interfaceId));
        assert.equal(res, true, "contract does not support ArrayExtraData interface");
    });

    it("testing type", async () => {
        let market = await HouseDecorationMarketPlace.deployed();
        let {status, '1': type} = await market.getType();
        assert.equal(status.toNumber(), 0, "status wasn't successful");
        assert.equal(type, "eu.sofie-iot.offer-marketplace-demo.house-renovation", "type of marketplace is not correct");
    });

});
