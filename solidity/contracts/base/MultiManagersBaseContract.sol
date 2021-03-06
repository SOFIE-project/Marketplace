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

import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol"; 
import "@openzeppelin/contracts/access/Roles.sol";
import "../interfaces/MultiManagers.sol";
import "../StatusCodes.sol";

contract MultiManagersBaseContract is MultiManagers, Ownable, ERC165, StatusCodes {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    using Roles for Roles.Role;
    Roles.Role internal managers;

    // Check if the given address is defined as a manager.
    function isManager(address addr) internal view returns (bool) {
        return managers.has(addr);
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
    constructor(address creator) public Ownable() {
        managers.add(creator);
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(this.changeOwner.selector
                            ^ this.addManager.selector
                            ^ this.revokeManagerCert.selector);
    }

    // The owner can transfer the rights of being owner to another address (only owner can access this function).
    function changeOwner(address addr) public returns (uint8 status) {
        if(msg.sender != owner()) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        require(msg.sender == owner());
        addManager(addr);
        transferOwnership(addr);
        emit FunctionStatus(Successful);
        return Successful;
    }

    // The owner can add a new address to the list of managers (only owner can access this function).
    function addManager(address managerAddress) public returns (uint8 status) {
        if(msg.sender != owner()) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        if (isManager(managerAddress)) {
            emit FunctionStatus(DuplicateManager);
            return DuplicateManager;
        }
        require(msg.sender == owner());
        managers.add(managerAddress);
        emit FunctionStatus(Successful);
        return Successful;
    }

    // The owner can revoke the certification of a current manager (only owner can access this function).
    function revokeManagerCert(address managerAddress) public returns (uint8 status) {
        if(msg.sender != owner()) {
            emit FunctionStatus(AccessDenied);
            return AccessDenied;
        }
        require(msg.sender == owner());
        managers.remove(managerAddress);
        return Successful;
    }
}
