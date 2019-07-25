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
pragma experimental ABIEncoderV2;

import "./ERC165.sol";
import "./MultiManagers.sol";

contract MultiManagersBaseContract is ERC165, MultiManagers {

    enum Status {Successful, AccessDenied, UndefinedID, DeadlinePassed, RequestNotOpen,
        NotPending, ReqNotDecided, ReqNotClosed, NotTimeForDeletion, AlreadySentOffer, ImproperList, DuplicateManager}

    address internal owner;
    address[] internal managers;

    event FunctionStatus(int status);

    // Check if the given address is defined as a manager.
    function isManager(address addr) internal view returns (bool) {
        for (uint j = 0; j < managers.length; j++) {
            if (managers[j] == addr) {
                return true;
            }
        }
        return false;
    }

    // Only let the owner to access a function
/*    modifier ownerAccess {//
        require(msg.sender == owner);
        _;
    }*/

    // Only let the owner or managers access a function
/*    modifier ownerOrManagerAccess {//
        require(msg.sender == owner || isManager(msg.sender));
        _;
    }*/

    constructor(address creator) public {
        managers.push(creator);
        owner = creator;
    }

    // The owner can transfer the rights of being owner to another address (only owner can access this function).
    function transferOwnership(address addr) public returns (int status) {
        if(msg.sender != owner) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        require(msg.sender == owner);

        addManager(addr);
        owner = addr;
        emit FunctionStatus(int(Status.Successful));
        return int(Status.Successful);
    }

    // The owner can add a new address to the list of managers (only owner can access this function).
    function addManager(address managerAddress) public returns (int status) {
        if(msg.sender != owner) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        require(msg.sender == owner);

        for (uint j = 0; j < managers.length; j++) {
            if (managers[j] == managerAddress) {
                emit FunctionStatus(int(Status.DuplicateManager));
                return int(Status.DuplicateManager);
            }
        }
        managers.push(managerAddress);
        emit FunctionStatus(int(Status.Successful));
        return int(Status.Successful);
    }

    // The owner can get the list of managers.
    function getManagers() public view returns (int status, address[] memory managerAddresses) {
        return (int(Status.Successful), managers);
    }

    // The owner can revoke the certification of a current manager (only owner can access this function).
    function revokeManagerCert(address managerAddress) public returns (int status) {
        if(msg.sender != owner) {
            emit FunctionStatus(int(Status.AccessDenied));
            return int(Status.AccessDenied);
        }
        require(msg.sender == owner);

        for (uint j = 0; j < managers.length; j++) {
            if (managers[j] == managerAddress) {
                for (uint i = j; i < managers.length - 1; i++){
                    managers[i] = managers[i+1];
                }
                delete managers[managers.length-1];
                managers.length--;
                emit FunctionStatus(int(Status.Successful));
                return int(Status.Successful);
            }
        }
    }

    // ERC165
    function supportsInterface(bytes4 interfaceID) public view returns (bool) {
        return
          interfaceID == this.supportsInterface.selector || // ERC165
          interfaceID == (this.transferOwnership.selector
                         ^ this.addManager.selector
                         ^ this.getManagers.selector
                         ^ this.revokeManagerCert.selector); // MultiManagers
    }

}
