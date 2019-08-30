pragma solidity ^0.5.8;

import "./AbstractManageableMarketPlace.sol";
import "../base/MultiManagersBaseContract.sol";

contract AbstractOwnerManagerMarketPlace is AbstractManageableMarketPlace, MultiManagersBaseContract {

    constructor() MultiManagersBaseContract(msg.sender) public {

    }

    function getMarketInformation() public view returns (uint8 status, address ownerAddress) {
        return (Successful, owner());
    }
}