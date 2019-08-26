from typing import List

import dateparser

import sofie_offer_marketplace as om
from datetime import datetime
import time


class FlowerRequest(om.Request):
    types = ['rose', 'tulip', 'jasmine', 'white']

    def __init__(self, quantity=None, type=None, **kwargs):
        super().__init__(**kwargs)
        self.quantity = quantity
        self.type = type

        # this could be made into a general mixin
        if 'decided_offers' in kwargs and kwargs['decided_offers']:
            assert (len(kwargs['decided_offers']) == 1), \
                "flower market can only have one decided offer"

            self.decided_offer = kwargs['decided_offers'][0]
        else:
            self.decided_offer = None

    @classmethod
    def from_data(cls, request_id, common, extra=None, init_args={}):
        init_args['quantity'] = extra[0]
        init_args['type'] = extra[1]

        return super(FlowerRequest, cls).from_data(
            request_id, common, init_args=init_args)

    @classmethod
    def from_args(cls, deadline, args):
        return cls(
            quantity=int(args[0]),
            type=int(args[1]) if args[1].isdigit() else cls.types.index(args[1]),
            deadline=deadline
        )

    has_extra = True

    def marshal_extra(self):
        return [[self.quantity, self.type]]

    @property
    def stage_str(self):
        if self.is_pending:
            return "PENDING"
        if self.is_open:
            return "OPEN"
        if self.is_closed:
            return "CLOSED"
        return "INVALID"

    def __str__(self):

        return "{} of {} ({}) by {} ({}){:>6}{:>5}{}".format(
            self.quantity, FlowerRequest.types[self.type], self.type,
            datetime.fromtimestamp(self.deadline).isoformat(), self.deadline,
            "PAST " if self.deadline < time.time() else "",
            self.stage_str,
            " DECIDED" if self.is_decided else "")


class FlowerOffer(om.Offer):
    def __init__(self, price=None, **kwargs):
        super().__init__(**kwargs)
        self.price = price

    @classmethod
    def from_data(cls, offer_id, common, extra=None, init_args={}):
        init_args['price'] = extra[0]
        return super(FlowerOffer, cls).from_data(
            offer_id, common, init_args=init_args)

    @classmethod
    def from_args(cls, request_id, args):
        return cls(
            request_id=request_id,
            price=int(args[0])
        )

    has_extra = True

    def marshal_extra(self):
        return [[self.price]]

    def __str__(self):
        return "price {} (@{})".format(self.price, self.author or "unset")


class TypeMapping:
    type_mapping = {
        "eu.sofie-iot.offer-marketplace-demo.flower": (FlowerRequest, FlowerOffer)
    }
