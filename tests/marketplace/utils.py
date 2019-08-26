from typing import Any, Dict, List, Optional
import sofie_offer_marketplace as om


# TODO: These effectively implement a python-only flower market
# scenario. Perhaps they could be moved to be a generic one? Also, we
# should have integration tests that run against a real flower market
# instance. Maybe just have a flag that selects between python-only
# and ethereum-backed contracts?


class MockRequest(om.Request):
    def __init__(self, request_id: int = None, **kwargs) -> None:
        quantity, type = kwargs.pop('quantity', None), kwargs.pop('type', None)
        super().__init__(request_id=request_id, **kwargs)
        self.quantity = quantity
        self.type = type

    has_extra = True

    def marshal_extra(self):
        return [self.quantity, self.type]

    @classmethod
    def from_data(cls, request_id, common, extra=None, init_args={}):
        init_args['quantity'] = extra[0]
        init_args['type'] = extra[1]
        return super(MockRequest, cls).from_data(
            request_id, common, init_args=init_args)


class MockOffer(om.Offer):
    def __init__(self, **kwargs):
        price = kwargs.pop('price', None)
        super().__init__(**kwargs)
        self.price = price

    has_extra = True

    def marshal_extra(self):
        return [self.price]

    @classmethod
    def from_data(cls, offer_id, common, extra=None, init_args={}):
        init_args['price'] = extra[0]
        return super(MockOffer, cls).from_data(
            offer_id, common, init_args=init_args)


class MockContract(om.Contract):
    @property
    def next_counter(self):
        self.counter += 1
        return self.counter

    def __init__(self, requests=[], offers=[], type_name="mocktype") -> None:
        self.requests = list(requests)
        self.offers = list(offers)
        self.type_name = type_name
        self.counter = 0

    def get_request_ids(self) -> List[int]:
        return [r.request_id for r in self.requests]

    def _get_request(self, request_id: int) -> Optional[MockRequest]:
        for r in self.requests:
            if r.request_id == request_id:
                return r
        return None

    def _get_offer(self, offer_id: int) -> Optional[MockOffer]:
        for o in self.offers:
            if o.offer_id == offer_id:
                return o
        return None

    def get_request(self, request_id: int) -> Optional[Dict[str, Any]]:
        r = self._get_request(request_id)
        if r is None:
            return None

        return {'deadline': r.deadline,
                'is_decided': r.is_decided,
                'is_pending': r.is_pending,
                'is_open': r.is_open,
                'is_closed': r.is_closed,
                'offer_ids': [o.offer_id for o in r.offers],
                'decided_offer_ids': [o.offer_id for o in r.decided_offers]}

    def get_request_extra(self, request_id: int) -> Any:
        r = self._get_request(request_id)
        if r is None:
            return None
        return r.marshal_extra()

    def add_request(self, deadline: int) -> int:
        request = MockRequest(self.next_counter)
        assert request.request_id is not None
        self.requests.append(request)
        return request.request_id

    def add_request_extra(self, request_id: int, extra: List[Any]) -> bool:
        r = self._get_request(request_id)
        if r is None or len(extra) != 2:
            return False
        quantity, type = extra
        r.quantity = quantity
        r.type = type

        return True

    def decide_request(self, request_id: int,
                       selected_offer_ids: List[int] = []) -> bool:
        r = self._get_request(request_id)

        if r is None:
            return False

        if r.is_decided:
            return True

        selected_offer = None

        for o in r.offers:
            if selected_offer is None or selected_offer.price < o.price:
                selected_offer = o

        if selected_offer is not None:
            r.decided_offers = [selected_offer]
        else:
            r.decided_offers = []

        r.is_decided = True
        r.is_closed = True
        r.is_open = False

        return True

    def get_offer(self, offer_id: int) -> Optional[Dict[str, Any]]:
        o = self._get_offer(offer_id)

        if o is None:
            return None

        return {'request_id': o.request_id,
                'author': o.author}

    def get_offer_extra(self, offer_id: int) -> Any:
        o = self._get_offer(offer_id)
        if o is None:
            return False
        return o.marshal_extra()

    def add_offer(self, request_id: int) -> int:
        offer = MockOffer(offer_id=self.next_counter, request_id=request_id)
        self.offers.append(offer)
        return offer.offer_id

    def add_offer_extra(self, offer_id: int, extra: List[Any]) -> bool:
        o = self._get_offer(offer_id)
        if o is None:
            return False
        o.price = extra[0]
        return True

    def get_type(self) -> str:
        return self.type_name
