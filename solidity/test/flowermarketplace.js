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

var FlowerMarketPlace = artifacts.require("FlowerMarketPlace");

contract('FlowerMarketPlace', function(accounts) {

    it("testing owner & managers", function(done) {
        var market;
        FlowerMarketPlace.deployed().then(function(instance) {
            market = instance;
            return market.getMarketInformation();
        }).then(function(ownerAdd) {
            assert.equal(ownerAdd[0].toNumber(), 0, "status wasn't successful");
            assert.equal(ownerAdd[1], accounts[0], "acconts[0] wasn't the initial owner");
        }).then(function() {
            market.addManager(accounts[1]);
        }).then(function() {
            market.addManager(accounts[2]);
        }).then(function() {
            market.addManager(accounts[0]);
        }).then(function() {
            return market.addManager(accounts[3]);
        }).then(function(tx) {
            assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            market.revokeManagerCert(accounts[1]);
        }).then(function() {
            market.revokeManagerCert(accounts[3]);
        }).then(function() {
            market.addManager(accounts[1]);
        }).then(function() {
            return market.changeOwner(accounts[3]);
        }).then(function(tx) {
            assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            return market.getMarketInformation();
        }).then(function(ownerAdd1) {
            assert.equal(ownerAdd1[1], accounts[3], "acconts[3] wasn't the owner");
        }).then(function() {
            market.changeOwner(accounts[0], {from: accounts[3]});
        }).then(function() {
            return market.getMarketInformation();
        }).then(function(ownerAdd2) {
            assert.equal(ownerAdd2[1], accounts[0], "acconts[0] wasn't the owner");
            done();
        });
    });

    it("testing requests & offers", function(done) {
        var market;
        FlowerMarketPlace.deployed().then(function(instance) {
            market = instance;
        }).then(function() {
            return market.submitRequest(2000000000);
        }).then(function(tx1) {
            assert.equal(tx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            assert.equal(tx1.logs[1].args.requestID.toNumber(), 1, "requestID wasn't 1");
            assert.equal(tx1.logs[1].args.deadline.toNumber(), 2000000000, "quantity wasn't 2000000000");
            return market.submitRequestExtra(tx1.logs[1].args.requestID, 20, 3);
        }).then(function(txx) {
            assert.equal(txx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            assert.equal(txx.logs[1].args.requestID.toNumber(), 1, "requestID wasn't 1");
            assert.equal(txx.logs[1].args.quantity.toNumber(), 20, "quantity wasn't 20");
            assert.equal(txx.logs[1].args.flowerType.toNumber(), 3, "flowerType wasn't 3 (White)");
            return market.submitRequest(2000000000);
        }).then(function(tx2) {
            market.submitRequestExtra(tx2.logs[1].args.requestID, 45, 0);
        }).then(function() {
            return market.submitRequest(2000000000);
        }).then(function(tx3) {
            market.submitRequestExtra(tx3.logs[1].args.requestID, 100, 2);
        }).then(function() {
            return market.closeRequest(2);
        }).then(function(txx1) {
            assert.equal(txx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            return market.getOpenRequestIdentifiers();
        }).then(function(openReqs) {
            assert.equal(openReqs[0].toNumber(), 0, "status wasn't successful");
            assert.equal(openReqs[1][0].toNumber(), 1, "openReqs[0] wasn't 1");
            assert.equal(openReqs[1][1].toNumber(), 3, "openReqs[1] wasn't 3");
        }).then(function() {
            return market.isRequestDefined(2);
        }).then(function(isDef1) {
            assert.equal(isDef1[0].toNumber(), 0, "status wasn't successful");
            assert.equal(isDef1[1], true, "request#2 wasn't defined");
        }).then(function() {
            return market.isRequestDefined(8);
        }).then(function(isDef2) {
            assert.equal(isDef2[0].toNumber(), 0, "status wasn't successful");
            assert.equal(isDef2[1], false, "request#8 was defined!!!");
        }).then(function() {
            return market.getRequest(3);
        }).then(function(req3) {
            assert.equal(req3[0].toNumber(), 0, "status wasn't successful");
            assert.equal(req3[1].toNumber(), 2000000000, "req3 deadline wasn't 2000000000");
            assert.equal(req3[2].toNumber(), 1, "req3 wasn't open");
        }).then(function() {
            return market.getRequestExtra(3);
        }).then(function(ext3) {
            assert.equal(ext3[0].toNumber(), 0, "status wasn't successful");
            assert.equal(ext3[1].toNumber(), 100, "req3 quantity wasn't 100");
            assert.equal(ext3[2].toNumber(), 2, "req3 flowerType wasn't 2");
        }).then(function() {
            return market.submitOffer(3, {from: accounts[6]});
        }).then(function(tx1) {
            assert.equal(tx1.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            assert.equal(tx1.logs[1].args.offerID.toNumber(), 1, "offerID wasn't 1");
            assert.equal(tx1.logs[1].args.requestID.toNumber(), 3, "requestID wasn't 3");
            assert.equal(tx1.logs[1].args.offerMaker, accounts[6], "offerMaker wasn't accounts[6]");
            return market.submitOfferExtra(tx1.logs[1].args.offerID, 100, {from: accounts[6]});
        }).then(function(txx) {
            assert.equal(txx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            assert.equal(txx.logs[1].args.offerID.toNumber(), 1, "offerID wasn't 1");
            assert.equal(txx.logs[1].args.price.toNumber(), 100, "price wasn't 100");
            return market.submitOffer(3, {from: accounts[8]});
        }).then(function(tx2) {
            market.submitOfferExtra(tx2.logs[1].args.offerID, 13, {from: accounts[8]});
        }).then(function() {
            return market.submitOffer(3, {from: accounts[2]});
        }).then(function(tx3) {
            market.submitOfferExtra(tx3.logs[1].args.offerID, 666, {from: accounts[2]});
        }).then(function() {
            return market.submitOffer(3);
        }).then(function(tx4) {
            market.submitOfferExtra(tx4.logs[1].args.offerID, 593);
        }).then(function() {
            return market.isOfferDefined(2);
        }).then(function(isOdef1) {
            assert.equal(isOdef1[0].toNumber(), 0, "status wasn't successful");
            assert.ok(isOdef1[1], "offer #2 wasn't defined");
        }).then(function() {
            return market.isOfferDefined(22);
        }).then(function(isOdef2) {
            assert.equal(isOdef2[0].toNumber(), 0, "status wasn't successful");
            assert.equal(isOdef2[1], false, "offer #22 was defined");
        }).then(function() {
            return market.getOffer(2);
        }).then(function(off2) {
            assert.equal(off2[0].toNumber(), 0, "status wasn't successful");
            assert.equal(off2[1].toNumber(), 3, "off2 requestID wasn't 3");
            assert.equal(off2[2], accounts[8], "off2 offerMaker wasn't accounts[8]");
            assert.equal(off2[3].toNumber(), 1, "off2 wasn't open");
        }).then(function() {
            return market.getOfferExtra(2);
        }).then(function(ext2) {
            assert.equal(ext2[0].toNumber(), 0, "status wasn't successful");
            assert.equal(ext2[1].toNumber(), 13, "off2 price wasn't 13");
        }).then(function() {
            return market.getRequestOfferIDs(3, {from: accounts[1]});
        }).then(function(offIDs) {
            assert.equal(offIDs[0].toNumber(), 0, "status wasn't successful");
            assert.equal(offIDs[1][0].toNumber(), 1, "offIDs[0] wasn't 1");
            assert.equal(offIDs[1][1].toNumber(), 2, "offIDs[1] wasn't 2");
            assert.equal(offIDs[1][2].toNumber(), 3, "offIDs[2] wasn't 3");
            assert.equal(offIDs[1][3].toNumber(), 4, "offIDs[3] wasn't 4");
        }).then(function() {
            market.decideRequest(3, []);
        }).then(function() {
            return market.isRequestDecided(3);
        }).then(function(isDec1) {
            assert.equal(isDec1[0].toNumber(), 0, "status wasn't successful");
            assert.equal(isDec1[1], true, "request#3 wasn't decided");
        }).then(function() {
            return market.isRequestDecided(2);
        }).then(function(isDec2) {
            assert.equal(isDec2[0].toNumber(), 0, "status wasn't successful");
            assert.equal(isDec2[1], false, "request#2 was decided!!!");
        }).then(function() {
            return market.getRequestDecision(3);
        }).then(function(accOffID) {
            assert.equal(accOffID[0].toNumber(), 0, "status wasn't successful");
            assert.equal(accOffID[1][0].toNumber(), 3, "accepted offer ID wasn't 3 (666)");
        }).then(function() {
            return market.getClosedRequestIdentifiers();
        }).then(function(closedReqs1) {
            assert.equal(closedReqs1[0].toNumber(), 0, "status wasn't successful");
            assert.equal(closedReqs1[1][0].toNumber(), 2, "closedReqs[0] wasn't 2");
            assert.equal(closedReqs1[1][1].toNumber(), 3, "closedReqs[1] wasn't 3");
        }).then(function() {
            return market.deleteRequest(2);
        }).then(function(tx) {
            assert.equal(tx.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            return market.getClosedRequestIdentifiers();
        }).then(function(closedReqs2) {
            assert.equal(closedReqs2[0].toNumber(), 0, "status wasn't successful");
            assert.equal(closedReqs2[1][0].toNumber(), 3, "closedReqs[0] wasn't 3");
            done();
        });
    });

    it("testing status codes", function(done) {
        var market;
        FlowerMarketPlace.deployed().then(function(instance) {
            market = instance;
        }).then(function() {
            return market.addManager(accounts[7], {from: accounts[9]});
        }).then(function(res1) {
            assert.equal(res1.logs[0].args.status.toNumber(), 1, "status should've been access denied");
            return market.getRequest(56);
        }).then(function(res2) {
            assert.equal(res2[0].toNumber(), 2, "status should've been undefinedID");
            return market.submitRequest(50);
        }).then(function(res3) {
            return market.submitOffer(res3.logs[1].args.requestID);
        }).then(function(res4) {
            assert.equal(res4.logs[0].args.status.toNumber(), 3, "status should've been deadline passed");
            return market.submitRequest(2000000000);
        }).then(function(res5) {
            return market.submitOffer(res5.logs[1].args.requestID);
        }).then(function(res6) {
            assert.equal(res6.logs[0].args.status.toNumber(), 4, "status should've been request not open");
            return market.submitOffer(1);
        }).then(function(res7) {
            return market.submitOfferExtra(res7.logs[1].args.offerID.toNumber(), 252);
        }).then(function(res8) {
            assert.equal(res8.logs[0].args.status.toNumber(), 0, "status wasn't successful");
            return market.submitOfferExtra(res8.logs[1].args.offerID.toNumber(), 254);
        }).then(function(res9) {
            assert.equal(res9.logs[0].args.status.toNumber(), 5, "status should've been not pending");
            return market.getRequestDecision(1);
        }).then(function(res10) {
            assert.equal(res10[0], 6, "status should've been request not decided");
            return market.deleteRequest(1);
        }).then(function(res11) {
            assert.equal(res11.logs[0].args.status.toNumber(), 7, "status should've been request not closed");
            done();
        });
    });

});
