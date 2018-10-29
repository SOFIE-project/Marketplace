#!/usr/bin/env python
# This will be refactored into proper suite, now just quick hack for
# testing.

import os
import asyncio
import argparse
import json
import sofie_offer_marketplace as om
import time
import dateparser
import typing
from datetime import datetime
from web3 import Web3, HTTPProvider, TestRPCProvider
from web3.contract import ConciseContract
from sofie_offer_marketplace.ethereum import Web3Contract


def get_parser():
    p = argparse.ArgumentParser()

    p.add_argument('--account', metavar='ACCOUNT',
                   help="""Account to use to access Ethereum (defaults to env.
                   variable FLOWER_ACCOUNT)""")
    p.add_argument('--password', metavar='PASSWORD',
                   help="""Password to unlock the Ethereum account (defaults to
                   env. variable FLOWER_ACCOUNT_PASSWORD, or '')""")
    p.add_argument('--contract', metavar='CONTRACT-ADDRESS',
                   help="""Address of the flower marketplace contract
                   (defaults to env. variable FLOWER_CONTRACT)""")
    p.add_argument('--interface-file',
                   default='solidity/build/contracts/FlowerMarketPlace.json',
                   help="""Path to the flower marketplace contract
                   interface definition file (defaults to
                   'solidity/build/contracts/FlowerMarketPlace.json'""")
    p.add_argument('--manager', action='store_true')
    p.add_argument('--owner', action='store_true')

    sp = p.add_subparsers(dest='command')

    rp = sp.add_parser("list-requests", aliases=['list'])

    arp = sp.add_parser("add-request")
    arp.add_argument('quantity', metavar='QUANTITY', nargs='?',
                     type=int, default=1)
    arp.add_argument('type', metavar='TYPE', nargs='?', default=0,
                     type=lambda v: int(v) if v.isdigit()
                     else FlowerRequest.types.index(v),
                     help="""Flower type, one of rose, tulip,
                     jasmine or white (default is rose)""")
    arp.add_argument('deadline', metavar='DEADLINE', nargs='?',
                     type=lambda v: int(dateparser.parse(v).timestamp()),
                     default=int(time.time()) + 3600,
                     help="""Request deadline, default in now + 1 hour,
                     uses `dateparser` so
                     things like 'tomorrow', 'in 3 weeks' and
                     '2020-02-01' work""")

    srp = sp.add_parser('show-request', aliases=["show"])
    srp.add_argument('request', metavar='REQUEST', type=int)

    drp = sp.add_parser('decide-request')
    drp.add_argument('request', metavar='REQUEST', type=int)

    aop = sp.add_parser("add-offer")
    aop.add_argument('request', metavar='REQUEST', type=int,
                     help='Request identifier')
    aop.add_argument('price', metavar='PRICE', type=int,
                     help='Price of offer')

    # market info
    # decide request
    # add manager
    # remove manager
    # owner change
    # deploy contract too??

    p.set_defaults(command='list-requests',
                   account=os.environ.get('FLOWER_ACCOUNT'),
                   contract=os.environ.get('FLOWER_CONTRACT'),
                   password=os.environ.get('FLOWER_ACCOUNT_PASSWORD', ''))
    return p


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

    has_extra = True

    def marshal_extra(self):
        return [self.quantity, self.type]

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
            "PAST" if self.deadline < time.time() else "",
            self.stage_str,
            "DECIDED" if self.is_decided else "")


class FlowerOffer(om.Offer):
    def __init__(self, price=None, **kwargs):
        super().__init__(**kwargs)
        self.price = price

    @classmethod
    def from_data(cls, offer_id, common, extra=None, init_args={}):
        init_args['price'] = extra[0]
        return super(FlowerOffer, cls).from_data(
            offer_id, common, init_args=init_args)

    has_extra = True

    def marshal_extra(self):
        return [self.price]

    def __str__(self):
        return "price {} (@{})".format(self.price, self.author or "unset")


async def main():
    args = get_parser().parse_args()
    contract_interface = json.loads(open(args.interface_file).read())

    w3 = Web3()

    if args.account:
        w3.eth.defaultAccount = args.account
    elif not w3.eth.defaultAccount:
        if not w3.eth.accounts:
            assert False, "no account specified, and no default available"
        w3.eth.defaultAccount = w3.eth.accounts[0]

    w3.personal.unlockAccount(w3.eth.defaultAccount, args.password, 1)

    c = Web3Contract(w3,
                     contract_address=args.contract,
                     contract_interface=contract_interface)

    m = om.Marketplace(
        contract=c,
        is_manager=args.manager,
        is_owner=args.owner,
        request_class=FlowerRequest,
        offer_class=FlowerOffer)

    if args.command in ['list-requests', 'list']:
        for r in m.get_requests():
            print("#{:<4} {}".format(r.request_id, str(r)))

    elif args.command == 'add-request':
        request = FlowerRequest(quantity=args.quantity,
                                type=args.type,
                                deadline=args.deadline)
        final_request = await m.add_request(request)
        print("{} (#{}) added into block {}, {} gas used".format(
            final_request, final_request.request_id,
            c.last_block_number, c.last_gas_used))
    elif args.command == 'decide-request':
        request = m.get_request(args.request)
        if request is None:
            print("Request {} does not exist".format(args.request))
        elif request.is_decided:
            print("Request {} has already been decided".format(
                request.request_id))
        else:
            # flower market SC is decision maker
            if await m.decide_request(request):
                print("Request {} has now been decided".format(
                    request.request_id))
            else:
                print("Request {} could notbe decided".format(
                    request.request_id))
    elif args.command in ['show-request', 'show']:
        request = m.get_request(args.request)
        if request is None:
            print("Request {} does not exist".format(args.request))
        else:
            print("""Request #{}

Generic:
  Deadline:   {}{}
  Decided:    {}
  Pending:    {}
  Open:       {}
  Closed:     {}

Market specific:
  Quantity:   {}
  Type:       {} ({})
""".format(request.request_id,
           datetime.fromtimestamp(request.deadline),
           " (PAST)" if request.deadline < time.time() else "",
           "Yes" if request.is_decided else "No",
           "Yes" if request.is_pending else "No",
           "Yes" if request.is_open else "No",
           "Yes" if request.is_closed else "No",
           request.quantity,
           FlowerRequest.types[request.type], request.type))

            if not request.offers:
                print("No offers")
            else:
                print("Offers:")

                for o in request.offers:
                    print("  #{:<4} {:<6} {}{}".format(
                        o.offer_id,
                        o.price,
                        o.author,
                        " (DECIDED)" if request.decided_offer and (o.offer_id == request.decided_offer.offer_id) else ""))

    elif args.command == 'add-offer':
        request = m.get_request(args.request)
        if request is None:
            print("Request {} does not exist".format(args.request))
        else:
            offer = FlowerOffer(request_id=request.request_id,
                                price=args.price)
            final_offer = await m.add_offer(offer)
            print(("Offer {} for request {} "
                   "added into block {}, {} gas used").format(
                final_offer, request.request_id,
                c.last_block_number, c.last_gas_used))
    else:
        assert False, "unhandled command {}".format(args.command)


if __name__ == '__main__':
    asyncio.get_event_loop().run_until_complete(main())
