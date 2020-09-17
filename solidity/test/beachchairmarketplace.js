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

var BeachChairMarketPlace = artifacts.require("BeachChairMarketPlace");

contract('BeachChairMarketPlace', function (accounts) {

    it("testing owner & managers", async () => {
        let market = await BeachChairMarketPlace.deployed();
        let {status, ownerAddress} = await market.getMarketInformation();
        assert.equal(status.toNumber(), 0, "status wasn't successful");
        assert.equal(ownerAddress, accounts[0], "acconts[0] wasn't the initial owner");
        await market.addManager(accounts[1]);
        await market.addManager(accounts[2]);
        await market.addManager(accounts[0]);
        let tx = await market.addManager(accounts[3]);
        assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        await market.revokeManagerCert(accounts[1]);
        await market.revokeManagerCert(accounts[3]);
        await market.addManager(accounts[1]);
        tx = await market.changeOwner(accounts[3]);
        assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let {ownerAddress: ownerAddress1} = await market.getMarketInformation();
        assert.equal(ownerAddress1, accounts[3], "acconts[3] wasn't the owner");
        await market.changeOwner(accounts[0], {from: accounts[3]});
        let {ownerAddress: ownerAddress2} = await market.getMarketInformation();
        assert.equal(ownerAddress2, accounts[0], "acconts[0] wasn't the owner");
    });

    it("testing requests & offers", async () => {
        let market = await BeachChairMarketPlace.deployed();
        let tx1 = await market.submitRequest(2000000000);
        assert.equal(tx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        assert.equal(tx1.logs[1].args.requestID.toNumber(), 1, "requestID wasn't 1");
        assert.equal(tx1.logs[1].args.deadline.toNumber(), 2000000000, "quantity wasn't 2000000000");
        let {requestMaker: requestMaker} = await market.getRequest(tx1.logs[1].args.requestID.toNumber());
        assert.equal(requestMaker, accounts[0], "request maker was not accounts[0]");
        let txx = await market.submitRequestArrayExtra(tx1.logs[1].args.requestID, [20, 20180809]);
        assert.equal(txx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        assert.equal(txx.logs[1].args.requestID.toNumber(), 1, "requestID wasn't 1");
        let {quantity, date} = await market.getRequestExtra(txx.logs[1].args.requestID.toNumber());
        assert.equal(quantity.toNumber(), 20, "quantity wasn't 20");
        assert.equal(date.toNumber(), 20180809, "date wasn't 20180809");
        let tx2 = await market.submitRequest(2000000000);
        await market.submitRequestArrayExtra(tx2.logs[1].args.requestID, [45, 20191111]);
        let tx3 = await market.submitRequest(2000000000);
        await market.submitRequestArrayExtra(tx3.logs[1].args.requestID, [100, 20180927]);
        let txx1 = await market.closeRequest(2);
        assert.equal(txx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let {status, '1': openReqs} = await market.getOpenRequestIdentifiers();
        assert.equal(status.toNumber(), 0, "status wasn't successful");
        assert.equal(openReqs[0].toNumber(), 1, "openReqs[0] wasn't 1");
        assert.equal(openReqs[1].toNumber(), 3, "openReqs[1] wasn't 3");
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
        let {status: statusx3, quantity: quantityx3, date: datex3} = await market.getRequestExtra(3);
        assert.equal(statusx3.toNumber(), 0, "status wasn't successful");
        assert.equal(quantityx3.toNumber(), 100, "req3 quantity wasn't 100");
        assert.equal(datex3.toNumber(), 20180927, "req3 date wasn't 20180927");
        tx1 = await market.submitOffer(3, {from: accounts[6]});
        assert.equal(tx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        assert.equal(tx1.logs[1].args.offerID.toNumber(), 1, "offerID wasn't 1");
        assert.equal(tx1.logs[1].args.requestID.toNumber(), 3, "requestID wasn't 3");
        assert.equal(tx1.logs[1].args.offerMaker, accounts[6], "offerMaker wasn't accounts[6]");
        txx = await market.submitOfferArrayExtra(tx1.logs[1].args.offerID, [83, 1200], {from: accounts[6]});
        assert.equal(txx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        assert.equal(txx.logs[1].args.offerID.toNumber(), 1, "offerID wasn't 1");
        let {quantity: quantityox, totalPrice: totalPriceox} = await market.getOfferExtra(txx.logs[1].args.offerID.toNumber());
        assert.equal(quantityox.toNumber(), 83, "quantity wasn't 83");
        assert.equal(totalPriceox.toNumber(), 1200, "totalPrice wasn't 1200");
        tx2 = await market.submitOffer(3, {from: accounts[8]});
        await market.submitOfferArrayExtra(tx2.logs[1].args.offerID, [13, 250], {from: accounts[8]});
        tx3 = await market.submitOffer(3, {from: accounts[2]});
        await market.submitOfferArrayExtra(tx3.logs[1].args.offerID, [25, 500], {from: accounts[2]});
        let tx4 = await market.submitOffer(3);
        await market.submitOfferArrayExtra(tx4.logs[1].args.offerID, [85, 1234]);
        let tx5 = await market.submitOffer(1, {from: accounts[6]});
        await market.submitOfferArrayExtra(tx5.logs[1].args.offerID, [34, 323], {from: accounts[6]});
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
        let {status: statusExt2, quantity: quantityExt2, totalPrice: totalPriceExt2} =
            await market.getOfferExtra(2);
        assert.equal(statusExt2.toNumber(), 0, "status wasn't successful");
        assert.equal(quantityExt2.toNumber(), 13, "off2 quantity wasn't 13");
        assert.equal(totalPriceExt2.toNumber(), 250, "off2 totalPrice wasn't 250");
        let {status: statusOffIDs, offerIDs: offIDs} = await market.getRequestOfferIDs(3, {from: accounts[1]});
        assert.equal(statusOffIDs.toNumber(), 0, "status wasn't successful");
        assert.equal(offIDs[0].toNumber(), 1, "offIDs[0] wasn't 1");
        assert.equal(offIDs[1].toNumber(), 2, "offIDs[1] wasn't 2");
        assert.equal(offIDs[2].toNumber(), 3, "offIDs[2] wasn't 3");
        assert.equal(offIDs[3].toNumber(), 4, "offIDs[3] wasn't 4");
        let accOfferIDs = [1, 2, 4];
        await market.decideRequest(3, accOfferIDs);
        let {status: statusIsDec1, '1': isDec1} = await market.isRequestDecided(3);
        assert.equal(statusIsDec1.toNumber(), 0, "status wasn't successful");
        assert.equal(isDec1, true, "request#3 wasn't decided");
        let {status: statusIsDec2, '1': isDec2} = await market.isRequestDecided(2);
        assert.equal(statusIsDec2.toNumber(), 0, "status wasn't successful");
        assert.equal(isDec2, false, "request#2 was decided!!!");
        let {status: statusAcc, acceptedOfferIDs: accOffIDs} = await market.getRequestDecision(3);
        assert.equal(statusAcc.toNumber(), 0, "status wasn't successful");
        assert.equal(accOffIDs[0].toNumber(), 1, "accepted offer ID[0] wasn't 1");
        assert.equal(accOffIDs[1].toNumber(), 2, "accepted offer ID[1] wasn't 2");
        assert.equal(accOffIDs[2].toNumber(), 4, "accepted offer ID[2] wasn't 4");
        let {status: statusClosedReqs1, '1': closedReqs1} = await market.getClosedRequestIdentifiers();
        assert.equal(statusClosedReqs1.toNumber(), 0, "status wasn't successful");
        assert.equal(closedReqs1[0].toNumber(), 2, "closedReqs[0] wasn't 2");
        assert.equal(closedReqs1[1].toNumber(), 3, "closedReqs[1] wasn't 3");
        let tx = await market.deleteRequest(2);
        assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let {status: statusClosedReqs2, '1': closedReqs2} = await market.getClosedRequestIdentifiers();
        assert.equal(statusClosedReqs2.toNumber(), 0, "status wasn't successful");
        assert.equal(closedReqs2[0].toNumber(), 3, "closedReqs[0] wasn't 3");
    });

    it("testing status codes", async () => {
        let market = await BeachChairMarketPlace.deployed();
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
        let res8 = await market.submitOfferArrayExtra(res7.logs[1].args.offerID, [11, 111]);
        assert.equal(res8.logs[0].args.status.toNumber(), 0, "status wasn't successful");
        let res9 = await market.submitOfferArrayExtra(res8.logs[1].args.offerID, [12, 112]);
        assert.equal(res9.logs[0].args.status.toNumber(), 5, "status should've been not pending");
        let res10 = await market.getRequestDecision(1);
        assert.equal(res10[0], 6, "status should've been request not decided");
        let res11 = await market.deleteRequest(1);
        assert.equal(res11.logs[0].args.status.toNumber(), 7, "status should've been request not closed");
        let res12 = await market.submitOffer(1, {from: accounts[6]});
        assert.equal(res12.logs[0].args.status.toNumber(), 9, "status should've been already send offer");
        let accOfferIDs1 = [5, 5];
        let res13 = await market.decideRequest(1, accOfferIDs1);
        assert.equal(res13.logs[0].args.status.toNumber(), 10, "status should've been improper list");
        let accOfferIDs2 = [4, 5];
        let res14 = await market.decideRequest(1, accOfferIDs2);
        assert.equal(res14.logs[0].args.status.toNumber(), 10, "status should've been improper list");
        let accOfferIDs3 = [5, 6];
        let res15 = await market.decideRequest(1, accOfferIDs3);
        assert.equal(res15.logs[0].args.status.toNumber(), 0, "status should've been successful");
    });

    it("testing ERC165 interface support", async () => {
        let market = await BeachChairMarketPlace.deployed();
        let erc165Selector = web3.eth.abi.encodeFunctionSignature('supportsInterface(bytes4)');
        let res = await market.supportsInterface(web3.utils.hexToBytes(erc165Selector));
        assert.equal(res, true, "contract does not support ERC165");
    });


    it("testing MultiManager interface support", async () => {
        let market = await BeachChairMarketPlace.deployed();
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
    //     let market = await BeachChairMarketPlace.deployed();
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
    //     // console.log(interfaceId) // '0x3c710eb4'
    //     let res = await market.supportsInterface(web3.utils.hexToBytes(interfaceId));
    //     assert.equal(res, true, "contract does not support MarketPlace interface");
    // });

    it("testing ManageableMarketPlace interface support", async () => {
        let market = await BeachChairMarketPlace.deployed();
        let interfaceFunctions = [
            'submitRequest(uint256)',
            'closeRequest(uint256)',
            'decideRequest(uint256,uint256[])',
            'deleteRequest(uint256)'
        ];

        let interfaceId = interfaceFunctions.map(web3.eth.abi.encodeFunctionSignature).map((x) => parseInt(x, 16)).reduce((x, y) => x ^ y);

        interfaceId = interfaceId > 0 ? interfaceId : 0xFFFFFFFF + interfaceId + 1;
        interfaceId = '0x' + interfaceId.toString(16);
        // console.log(interfaceId) //  0x8a18ead6
        let res = await market.supportsInterface(web3.utils.hexToBytes(interfaceId));
        assert.equal(res, true, "contract does not support ManageableMarketPlace interface");
    });

    it("testing ArrayExtraData interface support", async () => {
        let market = await BeachChairMarketPlace.deployed();
        let interfaceFunctions = [
            'submitOfferArrayExtra(uint256,uint256[])',
            'submitRequestArrayExtra(uint256,uint256[])'
        ];

        let interfaceId = interfaceFunctions.map(web3.eth.abi.encodeFunctionSignature).map((x) => parseInt(x, 16)).reduce((x, y) => x ^ y);

        interfaceId = interfaceId > 0 ? interfaceId : 0xFFFFFFFF + interfaceId + 1;
        interfaceId = '0x' + interfaceId.toString(16);
        // console.log(interfaceId); // 0x1ddeb71f
        let res = await market.supportsInterface(web3.utils.hexToBytes(interfaceId));
        assert.equal(res, true, "contract does not support ArrayExtraData interface");
    });

    it("testing type", async () => {
        let market = await BeachChairMarketPlace.deployed();
        let {status, '1': type} = await market.getType();
        assert.equal(status.toNumber(), 0, "status wasn't successful");
        assert.equal(type, "eu.sofie-iot.offer-marketplace-demo.beach-chair", "type of marketplace is not correct");
    });

});
