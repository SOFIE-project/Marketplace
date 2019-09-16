// -*- js -*-

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

/// Interface for contracts compliant to the SOFIE Offer Marketplace
/// behavior
///
/// No method of this interface should emit an error (``require`` or
/// similar) on what is considered "normal" error situations. They all
/// return the status code as the first int return value (aka
/// ``status``). If this is SUCCESS (e.g. value ``0``) then the other
/// return values are valid. Otherwise the caller should inspect the
/// ``status`` value and determine itself whether it can proceed.

interface MarketPlace {

    function getMarketInformation() external view returns (uint8 status, address ownerAddress);

    /// Returns the list of request identifiers for open requests,
    /// e.g. those for which new offers can be submitted.
    /// @return uint array of identifiers
    function getOpenRequestIdentifiers() external view returns (uint8 status, uint[] memory);

    function getClosedRequestIdentifiers() external view returns (uint8 status, uint[] memory);

    function getRequest(uint requestIdentifier) external view returns (uint8 status, uint deadline, uint stage, address requestMaker);

    function getRequestOfferIDs(uint requestIdentifier) external view returns (uint8 status, uint[] memory offerIDs);

    function isOfferDefined(uint offerIdentifier) external view returns (uint8 status, bool);

    function getOffer(uint offerIdentifier) external view returns (uint8 status, uint requestID, address offerMaker, uint stage);

    function submitOffer(uint requestID) external returns (uint8 status, uint offerID);

    function isRequestDefined(uint requestIdentifier) external view returns (uint8 status, bool);

    function isRequestDecided(uint requestIdentifier) external view returns (uint8 status, bool);

    function getRequestDecision(uint requestIdentifier) external view returns (uint8 status, uint[] memory acceptedOfferIDs);

    function getType() external view returns (uint8 status, string memory);

}
