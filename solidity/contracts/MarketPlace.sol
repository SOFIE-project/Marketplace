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

pragma solidity ^0.4.23;
pragma experimental ABIEncoderV2;

interface MarketPlace {

    function getMarketInformation() external view returns (int status, address ownerAddress);

    function getOpenRequestIdentifiers() external view returns (int status, uint[]);

    function getClosedRequestIdentifiers() external view returns (int status, uint[]);

    function getRequest(uint requestIdentifier) external view returns (int status, uint deadline, uint stage);

    function getRequestOfferIDs(uint requestIdentifier) external view returns (int status, uint[] offerIDs);

    function isOfferDefined(uint offerIdentifier) external view returns (int status, bool) ;

    function getOffer(uint offerIdentifier) external view returns (int status, uint requestID, address offerMaker, uint stage);

    function submitOffer(uint requestID) external returns (int status, uint offerID);

    function isRequestDefined(uint requestIdentifier) external view returns (int status, bool);

    function isRequestDecided(uint requestIdentifier) external view returns (int status, bool);

    function getRequestDecision(uint requestIdentifier) external view returns (int status, uint[] acceptedOfferIDs);

    function submitRequest(uint deadline) external returns (int status, uint requestID);

    function closeRequest(uint requestIdentifier) external returns (int status);

    function decideRequest(uint requestIdentifier, uint[] acceptedOfferIDs) external returns (int status);

    function deleteRequest(uint requestIdentifier) external returns (int status);

}
