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
import "./MarketPlace.sol";
import "./MultiManagersBaseContract.sol";
import "./ERC20Interface.sol";

contract EnergyMarketPlace is MarketPlace, MultiManagersBaseContract, ERC20Interface {
    enum Stage {Pending, Open, Closed}
    enum EnergyZone {Zone_1, Zone_2, Both}
    struct Request {
        uint ID;
        uint quantity;
        EnergyZone energyZone;
        uint maxPrice;
        address requestMaker;
        bool isPaid;
        uint deadline;
        uint startDate;
        uint endDate;
        uint requestDate;
        bool isDefined;
        Stage reqStage;
        bool isDecided;
        uint[] offerIDs;
        uint acceptedOfferID;
        uint closingBlock;
    }
    struct Offer {
        uint ID;
        uint price;
        uint requestID;
        address offerMaker;
        bool isDefined;
        Stage offStage;
    }
    uint waitBeforeDeleteBlocks;
    uint private reqNum;
    uint private offNum;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    mapping (uint => Request) private requests;
    mapping (uint => Offer) private offers;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint[] private openRequestIDs;
    uint[] private closedRequestIDs;
    event RequestAdded(uint requestID, uint deadline);
    event RequestExtraAdded(uint requestID, uint quantity, EnergyZone energyZone, uint maxPrice, uint startDate, uint endDate, uint requestDate);
    event OfferAdded(uint offerID, uint requestID, address offerMaker);
    event OfferExtraAdded(uint offerID, uint price);
    constructor() MultiManagersBaseContract(msg.sender) public {
        reqNum = 1;
        offNum = 1;
        waitBeforeDeleteBlocks = 1;
        symbol = "ST";
        name = "Sofie Token";
        decimals = 18;
        _totalSupply = 1000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    // TOKEN MANADGMENT
    // Get total supply
    function totalSupply() public view returns (uint) {
      return _totalSupply - balances[address(0)];
    }
    // Get balance of "tokenOwner"
    function balanceOf(address tokenOwner) public view returns (uint balance)
    {
      return balances[tokenOwner];
    }
    // Get allowed
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
      return allowed[tokenOwner][spender];
    }
    // Make a transfer from msg.sender to "to"
    function transfer(address to, uint tokens) public returns (bool success){
      balances[msg.sender] = balances[msg.sender] - tokens;
      balances[to] = balances[to] + tokens;
      emit Transfer(msg.sender, to, tokens);
      return true;
    }
    // Approve
    function approve(address spender, uint tokens) public returns (bool success){
      allowed[msg.sender][spender] = tokens;
      emit Approval(msg.sender, spender, tokens);
      return true;
    }
    // Make a transfer from "from" to "to"
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
      balances[from] = balances[from] - tokens;
      allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
      balances[to] = balances[to] + tokens;
      emit Transfer(from, to, tokens);
      return true;
    }
    // MARKETPLACE
    // Get the information of market, for example the owner, etc.
    function getMarketInformation() public view returns (int status, address ownerAddress) {
        return (int(Status.Successful), owner);
    }
    // Get the Identifiers of the requests which are not closed yet.
    function getOpenRequestIdentifiers() public view returns (int status, uint[]) {
        return (int(Status.Successful), openRequestIDs);
    }
    // Get the Identifiers of the requests which are closed.
    function getClosedRequestIdentifiers() public view returns (int status, uint[]) {
        return (int(Status.Successful), closedRequestIDs);
    }
    // Get general details of a request.
    function getRequest(uint requestIdentifier) public view returns (int status, uint deadline, uint stage) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), 0, 0);
        }
        require(requests[requestIdentifier].isDefined);
        return (int(Status.Successful), requests[requestIdentifier].deadline, uint(requests[requestIdentifier].reqStage));
    }
    // Get the specific stipulations of a request.
    function getRequestExtra(uint requestIdentifier) public view returns (int status, uint quantity, EnergyZone energyZone, uint maxPrice, address requestMaker, bool isPaid, uint startDate, uint endDate, uint requestDate) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), 0, EnergyZone(0), 0, 0, false, 0, 0, 0);
        }
        require(requests[requestIdentifier].isDefined);
        Request request = requests[requestIdentifier];
        return (int(Status.Successful), request.quantity, request.energyZone, request.maxPrice, request.requestMaker, request.isPaid, request.startDate, request.endDate, request.requestDate);
    }
    // Get offer identifiers for a request.
    function getRequestOfferIDs(uint requestIdentifier) public view returns (int status, uint[] offerIDs) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), new uint[](0));
        }
        require(requests[requestIdentifier].isDefined);
        return (int(Status.Successful), requests[requestIdentifier].offerIDs);
    }
    // Check if an offer with the specified offer identifier is defined.
    function isOfferDefined(uint offerIdentifier) public view returns (int status, bool) {
        return (int(Status.Successful), offers[offerIdentifier].isDefined);
    }
    // Get general details of an offer.
    function getOffer(uint offerIdentifier) public view returns (int status, uint requestID, address offerMaker, uint stage) {
        if(!offers[offerIdentifier].isDefined) {
            return (int(Status.UndefinedID), 0, 0, 0);
        }
        require(offers[offerIdentifier].isDefined);
        return (int(Status.Successful), offers[offerIdentifier].requestID, offers[offerIdentifier].offerMaker, uint(offers[offerIdentifier].offStage));
    }
    // Get specific details of an offer.
    function getOfferExtra(uint offerIdentifier) public view returns (int status, uint price) {
        if(!offers[offerIdentifier].isDefined) {
            return (int(Status.UndefinedID), 0);
        }
        require(offers[offerIdentifier].isDefined);
        return (int(Status.Successful), offers[offerIdentifier].price);
    }
    // By sending the identifier of a request, others can make offer to buy flowers.
    function submitOffer(uint requestID) public returns (int status, uint offerID) {
        if(!requests[requestID].isDefined) {
            emit FunctionStatus(int(Status.UndefinedID));
            return (int(Status.UndefinedID), 0);
        }
        if(now > requests[requestID].deadline) {
            emit FunctionStatus(int(Status.DeadlinePassed));
            return (int(Status.DeadlinePassed), 0);
        }
        if(requests[requestID].reqStage != Stage.Open) {
            emit FunctionStatus(int(Status.RequestNotOpen));
            return (int(Status.RequestNotOpen), 0);
        }
        require(requests[requestID].isDefined && now <= requests[requestID].deadline
            && requests[requestID].reqStage == Stage.Open);
        Offer memory offer;
        offer.requestID = requestID;
        offer.offerMaker = msg.sender;
        offer.ID = offNum;
        offNum += 1;
        offer.isDefined = true;
        offer.offStage = Stage.Pending;
        offers[offer.ID] = offer;
        requests[offer.requestID].offerIDs.push(offer.ID);
        emit FunctionStatus(int(Status.Successful));
        emit OfferAdded(offer.ID, offer.requestID, offer.offerMaker);
        return (int(Status.Successful), offer.ID);
    }
    // By sending the proposed price, others can complete and open their offer to buy flowers.
    // (only the initial offer maker can access this function).
    function submitOfferExtra(uint offerID, uint price) public returns (int status, uint offID) {
        Offer memory offer = offers[offerID];
        if(!offer.isDefined) {
            emit FunctionStatus(int(Status.UndefinedID));
            return (int(Status.UndefinedID), 0);
        }
        if(offer.offStage != Stage.Pending) {
            emit FunctionStatus(int(Status.NotPending));
            return (int(Status.NotPending), 0);
        }
        if(offer.offerMaker != msg.sender) {
            emit FunctionStatus(int(Status.AccessDenied));
            return (int(Status.AccessDenied), 0);
        }
        if(requests[offer.requestID].reqStage != Stage.Open) {
            emit FunctionStatus(int(Status.RequestNotOpen));
            return (int(Status.RequestNotOpen), 0);
        }
        require(offer.isDefined && offer.offStage == Stage.Pending
            && offer.offerMaker == msg.sender
            && requests[offer.requestID].reqStage == Stage.Open);
        offer.price = price;
        offer.offStage = Stage.Open;
        offers[offerID] = offer;
        emit FunctionStatus(int(Status.Successful));
        emit OfferExtraAdded(offerID, price);
        return (int(Status.Successful), offerID);
    }
    // Check if a request with the specified request identifier is defined.
    function isRequestDefined(uint requestIdentifier) public view returns (int status, bool) {
        return (int(Status.Successful), requests[requestIdentifier].isDefined);
    }
    // Check if a defined request with the specified request identifier is decided.
    function isRequestDecided(uint requestIdentifier) public view returns (int status, bool) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), false);
        }
        require(requests[requestIdentifier].isDefined);
        return (int(Status.Successful), requests[requestIdentifier].isDecided);
    }
    // Check if a defined request with the specified request identifier is paid.
    function isRequestPaid(uint requestIdentifier) public view returns (int status, bool) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), false);
        }
        require(requests[requestIdentifier].isPaid);
        return (int(Status.Successful), requests[requestIdentifier].isPaid);
    }
    function isRequestPay(uint requestIdentifier) public view returns (int status, bool) {
        if(!requests[requestIdentifier].isPaid) {
            return (int(Status.UndefinedID), false);
        }
        require(requests[requestIdentifier].isPaid);
        return (int(Status.Successful), requests[requestIdentifier].isPaid);
    }
    // Get the identifier of accepted offer for a decided request.
    function getRequestDecision(uint requestIdentifier) public view returns (int status, uint[] acceptedOfferIDs) {
        if(!requests[requestIdentifier].isDefined) {
            return (int(Status.UndefinedID), new uint[](0));
        }
        if(!requests[requestIdentifier].isDecided) {
            return (int(Status.ReqNotDecided), new uint[](0));
        }
        require(requests[requestIdentifier].isDefined && requests[requestIdentifier].isDecided);
        if(requests[requestIdentifier].acceptedOfferID != 0) {
            uint[] memory accoffIDs1 = new uint[](1);
            accoffIDs1[0] = requests[requestIdentifier].acceptedOfferID;
            return (int(Status.Successful), accoffIDs1);
        }
        else {
            uint[] memory accoffIDs2 = new uint[](0);
            return (int(Status.Successful), accoffIDs2);
        }
    }
    // By specifiying the deadline of the request, owner and managers
    // can add a new request. It will have a unique identifier and others will be able to make offers for it
    // (only owner or managers can access this function).
    function submitRequest(uint deadline) public returns (int status, uint requestID) {
        if(!(msg.sender == owner || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return (int(Status.AccessDenied), 0);
        }
        require(msg.sender == owner || isManager(msg.sender));
        Request memory request;
        request.deadline = deadline;
        request.ID = reqNum;
        reqNum += 1;
        request.isDefined = true;
        request.reqStage = Stage.Pending;
        request.isDecided = false;
        requests[request.ID] = request;
        emit FunctionStatus(int(Status.Successful));
        emit RequestAdded(request.ID, request.deadline);
        return (int(Status.Successful), request.ID);
    }
    // By specifiying the type of the flowers, quantity of them, owner and managers
    // can complete a request (only owner or managers can access this function).
    function submitRequestExtra(uint requestID, uint quantity, EnergyZone energyZone, uint maxPrice, uint startDate, uint endDate, uint requestDate) public returns (int status, uint reqID) {
        if(!(msg.sender == owner || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return (int(Status.AccessDenied), 0);
        }
        if(!requests[requestID].isDefined) {
            emit FunctionStatus(int(Status.UndefinedID));
            return (int(Status.UndefinedID), 0);
        }
        if(requests[requestID].reqStage != Stage.Pending) {
            emit FunctionStatus(int(Status.NotPending));
            return (int(Status.NotPending), 0);
        }
        require(msg.sender == owner || isManager(msg.sender));
        require(requests[requestID].isDefined && requests[requestID].reqStage == Stage.Pending);
        requests[requestID].quantity = quantity;
        requests[requestID].energyZone = energyZone;
        requests[requestID].maxPrice = maxPrice;
        requests[requestID].startDate = startDate;
        requests[requestID].endDate = endDate;
        requests[requestID].requestDate = requestDate;
        requests[requestID].requestMaker = msg.sender;
        requests[requestID].isPaid = false;
        openRequest(requestID);
        emit FunctionStatus(int(Status.Successful));
        emit RequestExtraAdded(requestID, quantity, energyZone, maxPrice, startDate, endDate, requestDate);
        return (int(Status.Successful), requestID);
    }
    // Open a request.
    function openRequest(uint requestIdentifier) private {
        requests[requestIdentifier].reqStage = Stage.Open;
        openRequestIDs.push(requests[requestIdentifier].ID);
    }
    // Manually close a request, so others won't be able to make offers for it or even see it in the list of requests.
    // In this implementation, this is completely apart from request's deadline. This can be modified based on the
    // specifications of the market we have (only owner or managers can access this function).
    function closeRequest(uint requestIdentifier) public returns (int status) {
        if(!(msg.sender == owner || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        require(msg.sender == owner || isManager(msg.sender));
        requests[requestIdentifier].reqStage = Stage.Closed;
        requests[requestIdentifier].closingBlock = block.number;
        closedRequestIDs.push(requestIdentifier);
        for (uint j = 0; j < openRequestIDs.length; j++) {
            if (openRequestIDs[j] == requestIdentifier) {
                for (uint i = j; i < openRequestIDs.length - 1; i++){
                    openRequestIDs[i] = openRequestIDs[i+1];
                }
                delete openRequestIDs[openRequestIDs.length-1];
                openRequestIDs.length--;
                emit FunctionStatus(int(Status.Successful));
                return int(Status.Successful);
            }
        }
    }
    // Choose which offer to accept, based on the proposed prices. The decision process can differ for other markets,
    // and it can be very complicated. Even in some cases, the decision must be made in the backend.
    // (only owner or managers can access this function).
    function decideRequest(uint requestIdentifier, uint[] /*acceptedOfferIDs*/) external returns (int status) {
        if(!(msg.sender == owner || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        require(msg.sender == owner || isManager(msg.sender));
        closeRequest(requestIdentifier);
        uint minOffer = requests[requestIdentifier].maxPrice;
        uint acceptedOfferID = 0;
        uint n = requests[requestIdentifier].offerIDs.length;
        for (uint i = 0; i < n ; i++) {
            Offer memory offer = offers[requests[requestIdentifier].offerIDs[n-1-i]];
            if (offer.offStage == Stage.Open && minOffer >= offer.price) {
                minOffer = offer.price;
                acceptedOfferID = requests[requestIdentifier].offerIDs[n-1-i];
            }
        }
        requests[requestIdentifier].acceptedOfferID = acceptedOfferID;
        requests[requestIdentifier].isDecided = true;
        emit FunctionStatus(int(Status.Successful));
        return int(Status.Successful);
    }
    function payment(uint requestID) external returns (bool status) {
      uint offerID = requests[requestID].acceptedOfferID;
      bool result = false;
      if(requests[requestID].isDecided == true && requests[requestID].isPaid == false) {
        result = transferFrom(requests[requestID].requestMaker,offers[offerID].offerMaker,offers[offerID].price * 10**uint(decimals));
      }
      if (result == true) {
        requests[requestID].isPaid = true;
        return true;
      }
      return false;
    }
    function deleteRequest(uint requestIdentifier) public returns (int status) {
        if(!(msg.sender == owner || isManager(msg.sender))) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        if(requests[requestIdentifier].reqStage != Stage.Closed) {
            emit FunctionStatus(int(Status.ReqNotClosed));
            return int(Status.ReqNotClosed);
        }
        if(requests[requestIdentifier].closingBlock + waitBeforeDeleteBlocks > block.number) {
            emit FunctionStatus(int(Status.NotTimeForDeletion));
            return int(Status.NotTimeForDeletion);
        }
        require(msg.sender == owner || isManager(msg.sender));
        require(requests[requestIdentifier].reqStage == Stage.Closed
            && requests[requestIdentifier].closingBlock + waitBeforeDeleteBlocks <= block.number);
        for (uint k = 0; k < requests[requestIdentifier].offerIDs.length; k++) {
            delete offers[requests[requestIdentifier].offerIDs[k]];
        }
        delete requests[requestIdentifier];
        for (uint j = 0; j < closedRequestIDs.length; j++) {
            if (closedRequestIDs[j] == requestIdentifier) {
                for (uint i = j; i < closedRequestIDs.length - 1; i++){
                    closedRequestIDs[i] = closedRequestIDs[i+1];
                }
                delete closedRequestIDs[closedRequestIDs.length-1];
                closedRequestIDs.length--;
                emit FunctionStatus(int(Status.Successful));
                return int(Status.Successful);
            }
        }
    }
    // ERC165
    function supportsInterface(bytes4 interfaceID) public view returns (bool) {
        return
          MultiManagersBaseContract.supportsInterface(interfaceID) ||
          interfaceID == (this.getMarketInformation.selector
                         ^ this.getOpenRequestIdentifiers.selector
                         ^ this.getClosedRequestIdentifiers.selector
                         ^ this.getRequest.selector
                         ^ this.getRequestOfferIDs.selector
                         ^ this.isOfferDefined.selector
                         ^ this.getOffer.selector
                         ^ this.submitOffer.selector
                         ^ this.isRequestDefined.selector
                         ^ this.isRequestDecided.selector
                         ^ this.getRequestDecision.selector
                         ^ this.submitRequest.selector
                         ^ this.closeRequest.selector
                         ^ this.decideRequest.selector
                         ^ this.deleteRequest.selector
                         ^ this.isRequestPaid.selector); // MarketPlace
    }
}
