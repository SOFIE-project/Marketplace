pragma solidity ^0.5.8;


contract StatusCodes {
    uint8 constant internal Successful = 0;
    uint8 constant internal AccessDenied = 1;
    uint8 constant internal UndefinedID = 2;
    uint8 constant internal DeadlinePassed = 3;
    uint8 constant internal RequestNotOpen = 4;
    uint8 constant internal NotPending = 5;
    uint8 constant internal ReqNotDecided = 6;
    uint8 constant internal ReqNotClosed = 7;
    uint8 constant internal NotTimeForDeletion = 8;
    uint8 constant internal AlreadySentOffer = 9;
    uint8 constant internal ImproperList = 10;
    uint8 constant internal DuplicateManager = 11;
    uint8 constant internal InvalidInput = 12;
    uint8 constant internal Fail= 13;

    event FunctionStatus(uint8 status);
}

