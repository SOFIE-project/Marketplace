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

from abc import ABCMeta, abstractmethod
from typing import Any, Dict, List, Optional
from .exceptions import ManagerAccessRequired, OwnerAccessRequired


class Contract(metaclass=ABCMeta):
    """This is the generic contract class that is used for interacting
    with the smart contract. It is purposefully abstracted to be not
    specific to Web3 for a couple of reasons. First it makes it easier
    to use other DLTs with the contract (but this is not a very good
    reason at the moment, though), secondly it makes unit testing a
    lot easier (much better reason) and thirdly, the Web3 (python
    library) interface is difficult to use in a way that is both
    isolated and easy to test.

    All of these methods are supposed to be blocking. It is the
    caller's responsibility to use asyncio if they want asynchronous
    operations.
    """

    @abstractmethod
    def get_request_ids(self) -> List[int]:
        """Returns a list of request identifiers"""

    @abstractmethod
    def get_request(self, request_id: int) -> Optional[Dict[str, Any]]:
        """Return a common request attributes for the given request id, or
        None if the given `request_id` does not map to a request. The
        common parameters are:

        - 'deadline': deadline in seconds since UNIX epoch
        - 'is_decided': boolean, is decided
        - 'is_pending': boolean, is pending
        - 'is_open': boolean, is open
        - 'is_closed': boolean, is closed
        - 'offer_ids': list of ids of offers made on this request
        - 'decided_offer_ids': list of decided offer ids, if decided,
          missing if not
        """

    @abstractmethod
    def get_request_extra(self, request_id: int) -> Any:
        """Returns the marketplace-specific extra attributes of the request"""

    @abstractmethod
    def add_request(self, deadline: int) -> int:
        """Create a new request with the given parameters, and return the
        identifier of the new request"""

    @abstractmethod
    def add_request_extra(self, request_id: int, extra: List[Any]) -> bool:
        """Add extra parameters to the given request. This returns true if the
        request could be completed, false otherwise."""

    @abstractmethod
    def decide_request(self, request_id: int,
                       selected_offer_ids: List[int] = []) -> bool:
        """Decides a request, offering the optional (sometimes ignored) list
        of selected offers. Returns true if decision was made, false
        if failed.

        """

    @abstractmethod
    def get_offer(self, offer_id: int) -> Optional[Dict[str, Any]]:
        """Returns common offer attributes for the given offer id, or None if
        the given `offer_id` does not map to an offer. The common
        offer attributes are:

        - 'request_id': request id of the offer
        - 'author': address of the offer-maker
        """

    @abstractmethod
    def get_offer_extra(self, request_id: int) -> Any:
        """Returns the marketplace-specific extra attributes of the offer"""

    @abstractmethod
    def add_offer(self, request_id: int) -> int:
        """Add a new offer for the given request"""

    @abstractmethod
    def add_offer_extra(self, offer_id: int, extra: List[Any]) -> bool:
        """Adds the extra data to the given offer"""


class Request(object):
    def __init__(self,
                 request_id: int = None,
                 deadline: int = None,
                 is_pending: bool = None,
                 is_decided: bool = None,
                 is_open: bool = None,
                 is_closed: bool = None,
                 # FIXME: when python 3.7 becomes minimum, we can
                 # change to PEP-563
                 offers: List['Offer'] = [],
                 decided_offers: List['Offer'] = [],
                 **kwargs) -> None:
        assert not kwargs, \
            (("Request base class initializer should not "
              "receive additional kwargs (was {!r}").format(kwargs))

        self.request_id = request_id
        self.deadline = deadline
        self.is_decided = is_decided
        self.is_pending = is_pending
        self.is_open = is_open
        self.is_closed = is_closed
        self.offers = offers
        self.decided_offers = decided_offers

    def marshal_extra(self) -> List[Any]:
        return []

    @classmethod
    def from_data(cls,
                  request_id: int,
                  common: Dict[str, Any],
                  extra: List[Any] = [],
                  init_args: Dict[str, Any] = {}):

        return cls(request_id=request_id,
                   deadline=common['deadline'],
                   is_decided=common['is_decided'],
                   is_pending=common['is_pending'],
                   is_open=common['is_open'],
                   is_closed=common['is_closed'],
                   offers=common['offers'],
                   decided_offers=common['decided_offers'],
                   **init_args)


class Offer(object):
    # NOTE: inconsistent... shouldn't request_id be instead request,
    # e.g. request object?
    def __init__(self,
                 offer_id=None,
                 request_id=None,
                 author=None,
                 **kwargs) -> None:
        assert not kwargs, \
            (("Offer base class initializer should not "
              "receive additional kwargs (was {!r}").format(kwargs))

        self.offer_id = offer_id
        self.request_id = request_id
        self.author = author

    def marshal_extra(self) -> List[Any]:
        return []

    @classmethod
    def from_data(cls,
                  offer_id: int,
                  common: Dict[str, Any],
                  extra: List[Any] = [],
                  init_args: Dict[str, Any] = {}):

        return cls(offer_id=offer_id,
                   request_id=common['request_id'],
                   author=common['author'],
                   **init_args)


# FIXME: we cannot really operate on web3 or contract directly, they
# are too low-level interfaces here for useful testing and
# abstraction. Need a facade or bridge that handles that and async
# bits nicely there.
#
# Also actually all of these calls could be blocking, so it is the
# responsibility of the **caller** to do async stuff if they really
# need it.

class Marketplace(object):
    def __init__(self,
                 contract: Contract,
                 is_owner: bool = False,
                 is_manager: bool = False,
                 # these are ok with duck typing
                 request_class=None,
                 offer_class=None) -> None:
        self.contract = contract
        self.is_manager = is_manager
        self.is_owner = is_owner
        self.request_class = request_class
        self.offer_class = offer_class

    def get_requests(self):
        """Returns list of current requests"""
        requests = []
        for request_id in self.contract.get_request_ids():
            request = self.get_request(request_id)
            assert request is not None, \
                "request id {!r} not found even if in list".format(request_id)
            requests.append(request)
        return requests

    def get_request(self, request_id):
        """Returns a specific request"""
        data = self.contract.get_request(request_id)

        if data is None:
            return None

        extra = self.contract.get_request_extra(request_id)

        # Turn offer_ids into offers
        data['offers'] = [
            self.get_offer(offer_id)
            for offer_id in data.pop('offer_ids', [])]

        # If we have decisions, turn them into offer objects
        data['decided_offers'] = [
            self.get_offer(offer_id)
            for offer_id in data.pop('decided_offer_ids', [])]

        assert None not in data['decided_offers']

        return self.request_class.from_data(
            request_id=request_id,
            common=data,
            extra=extra)

    def get_offers(self, request_id):
        """Returns offers made for a specific request"""
        # offers = []

        # for offer_id in self.contract.getRequestOfferIDs(request_id):
        #     offer = self.get_offer(offer_id)
        #     offers.append(offer)

        # return offers
        assert False, "not implemented, potentially to be removed"

    def get_offer(self, offer_id) -> Optional[Offer]:
        """Returns a specific offer"""
        data = self.contract.get_offer(offer_id)

        if data is None:
            return None

        extra = self.contract.get_offer_extra(offer_id)

        return self.offer_class.from_data(
            offer_id=offer_id,
            common=data,
            extra=extra)

    async def add_request(self, request):
        """Adds the request"""
        assert request.request_id is None

        if not self.is_manager:
            raise ManagerAccessRequired()

        request_id = self.contract.add_request(request.deadline)

        extra_ok = self.contract.add_request_extra(
            request_id,
            request.marshal_extra())

        assert extra_ok, "extra data could not be added to request"

        return self.get_request(request_id)

    # FIXME: adding an offer should occur via request object
    async def add_offer(self, offer):
        """Adds offer"""
        assert offer.offer_id is None and offer.request_id is not None

        offer_id = self.contract.add_offer(offer.request_id)

        extra_ok = self.contract.add_offer_extra(
            offer_id,
            offer.marshal_extra())

        assert extra_ok, "extra data could not be added to offer"

        return self.get_offer(offer_id)

    # FIXME: decide should be part of a request object
    async def decide_request(self, request, offers=[]):
        """Decides the request with the list of offers. Depending on the
        specific marketplace the list may be empty, or may contain multiple
        offers, or may be required to contain only one offer."""
        if not self.is_manager:
            raise ManagerAccessRequired()

        return self.contract.decide_request(request.request_id,
                                            [o.offer_id for o in offers])

    async def add_offerer(self, address):
        """Adds the specified offerer as a valid offerer, if the contract type
        supports the operation"""
        if not self.is_manager:
            raise ManagerAccessRequired()
        assert False, "Not implemented yet"

    async def remove_offerer(self, address):
        """Remove the specified offerer from the valid offerer list, if the
        contract type supports the operation"""
        if not self.is_manager:
            raise ManagerAccessRequired()
        assert False, "Not implemented yet"

    def list_offerers(self):
        """Returns the list of valid offerers, if the contract type supports
        restricted set of offers"""
        assert False, "Not implemented yet"

    async def add_manager(self, address):
        """Adds a specific address as a valid manager to the marketplace
        contract"""
        if not self.is_owner:
            raise OwnerAccessRequired()
        assert False, "Not implemented yet"

    async def remove_manager(self, address):
        """Removes manager access from the specific address in the marketplace
        contract"""
        if not self.is_owner:
            raise OwnerAccessRequired()
        assert False, "Not implemented yet"

    async def change_owner(self, address):
        """Irrecoveably changes the owner of the smart contract to the given
        address"""
        if not self.is_owner:
            raise OwnerAccessRequired()
        assert False, "Not implemented yet"
