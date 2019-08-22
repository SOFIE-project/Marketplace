# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed
# with this work for additional information regarding copyright
# ownership.  The ASF licenses this file to you under the Apache
# License, Version 2.0 (the "License"); you may not use this file
# except in compliance with the License.  You may obtain a copy of the
# License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.

from .core import Contract
from typing import Any, Dict, List, Optional, cast
from enum import Enum
from . import exceptions


class Status(Enum):
    Successful = 0
    AccessDenied = 1
    UndefinedID = 2
    DeadlinePassed = 3
    RequestNotOpen = 4
    NotPending = 5
    ReqNotDecided = 6
    ReqNotClosed = 7
    NotTimeForDeletion = 8
    AlreadySentOffer = 9
    ImproperList = 10
    DuplicateManager = 11


class Web3Contract(Contract):
    """Concrete implementation of the :class:`Contract` interface that
    works with Ethereum using the Web3 library. It requires a web3
    instance, and can be passed a contract, or a contract interface JSON
    object, or to be pointed to the contract interface file.

    All methods in this class are synchronous and **can block**
    indefinitely.
    """
    def __init__(self,
                 web3,
                 contract=None,
                 contract_address=None,
                 contract_interface=None,
                 contract_file=None):
        assert sum([v is not None for v in [contract, contract_interface, contract_file]]) == 1, "One and only one of contract, contract_interface and contract_file parameters may be specified"

        assert contract is not None or contract_address, "contract_address must be specified if contract_file or contract_interface are used"

        if contract_file is not None:
            contract_interface = json.loads(open(contract_file).read())

        if contract_interface is not None:
            contract = web3.eth.contract(
                address=contract_address,
                abi=contract_interface['abi'])

        # TODO: Here we should actually go and query the contract with
        # ERC-165 interface for SOFIE marketplace support

        self.web3 = web3
        self.contract = contract
        self.last_block_number = None
        self.last_gas_used = None

    def status(self, result: List[Any]) -> List[Any]:
        assert len(result) >= 1
        status = result[0]

        if status == Status.Successful.value:
            return result[1:]

        if status == Status.AccessDenied.value:
            raise exceptions.AccessDenied()

        assert False, \
            "sorry, error type {} not yet properly handled".format(status)

    def status1(self, result: List[Any]) -> Any:
        return self.status(result)[0]

    def get_request_ids(self) -> List[int]:
        return self.status1(
            self.contract.functions.getOpenRequestIdentifiers().call())

    def get_request(self, request_id: int) -> Optional[Dict[str, Any]]:
        if not self.status1(
                self.contract.functions.isRequestDefined(request_id).call()):
            return None

        deadline, stage = self.status(
            self.contract.functions.getRequest(request_id).call())

        is_pending = stage == 0
        is_open = stage == 1
        is_closed = stage == 2

        is_decided = self.status1(
            self.contract.functions.isRequestDecided(request_id).call())

        offer_ids = self.status1(
            self.contract.functions.getRequestOfferIDs(request_id).call())

        if is_decided:
            decided_ids = self.status1(
                self.contract.functions.getRequestDecision(request_id).call())
        else:
            decided_ids = []

        result = dict(deadline=deadline,
                      is_decided=is_decided,
                      is_pending=is_pending,
                      is_open=is_open,
                      is_closed=is_closed,
                      offer_ids=offer_ids,
                      decided_offer_ids=decided_ids)

        return result

    def get_request_extra(self, request_id: int) -> Any:
        if not self.status1(
                self.contract.functions.isRequestDefined(request_id).call()):
            return None

        extra = self.status(
            self.contract.functions.getRequestExtra(request_id).call())

        if isinstance(extra, list):
            return extra

        return [extra]

    def add_request(self, deadline: int) -> int:
        tx_hash = self.contract.functions.submitRequest(
            deadline).transact({'gas': 1000000})

        tx_receipt = self.web3.eth.waitForTransactionReceipt(tx_hash)

        self.last_block_number = tx_receipt.blockNumber
        self.last_gas_used = tx_receipt.gasUsed

        adds = self.contract.events.RequestAdded().processReceipt(tx_receipt)
        assert len(adds) == 1, "This should not happen"
        request_id = adds[0].args.requestID

        return request_id

    def add_request_extra(self, request_id: int, extra: List[Any]) -> bool:
        # FIXME: This is now tied to the flower market specifically
        tx_hash = self.contract.functions.submitRequestExtra(
            request_id,
            *extra).transact({'gas': 1000000})

        tx_receipt = self.web3.eth.waitForTransactionReceipt(tx_hash)

        self.last_block_number = tx_receipt.blockNumber
        self.last_gas_used = tx_receipt.gasUsed

        return True

    def get_offer(self, offer_id: int) -> Optional[Dict[str, Any]]:
        if not self.status1(
                self.contract.functions.isOfferDefined(offer_id).call()):
            return None

        request_id, author, stage = self.status(
            self.contract.functions.getOffer(offer_id).call())

        return dict(
            request_id=request_id,
            author=author,
            stage=stage)

    def get_offer_extra(self, offer_id: int) -> Any:
        if not self.status1(
                self.contract.functions.isOfferDefined(offer_id).call()):
            return None

        extra = self.status(
            self.contract.functions.getOfferExtra(offer_id).call())

        if isinstance(extra, list):
            return extra

        return [extra]

    def add_offer(self, request_id: int) -> int:
        tx_hash = self.contract.functions.submitOffer(
            request_id).transact({'gas': 1000000})

        tx_receipt = self.web3.eth.waitForTransactionReceipt(tx_hash)

        self.last_block_number = tx_receipt.blockNumber
        self.last_gas_used = tx_receipt.gasUsed

        adds = self.contract.events.OfferAdded().processReceipt(tx_receipt)
        assert len(adds) == 1, "This should not happen"
        offer_id = adds[0].args.offerID

        return offer_id

    def add_offer_extra(self, offer_id: int, extra: List[Any]) -> bool:
        # FIXME: This is now tied to the flower market specifically
        tx_hash = self.contract.functions.submitOfferExtra(
            offer_id,
            *extra).transact({'gas': 1000000})

        tx_receipt = self.web3.eth.waitForTransactionReceipt(tx_hash)

        self.last_block_number = tx_receipt.blockNumber
        self.last_gas_used = tx_receipt.gasUsed

        return True

    def decide_request(self, request_id: int,
                       selected_offer_ids: List[int] = []) -> bool:
        tx_hash = self.contract.functions.decideRequest(
            request_id,
            selected_offer_ids).transact({'gas': 1000000})

        tx_receipt = self.web3.eth.waitForTransactionReceipt(tx_hash)

        return cast(bool, self.status1(
            self.contract.functions.isRequestDecided(request_id).call()))
