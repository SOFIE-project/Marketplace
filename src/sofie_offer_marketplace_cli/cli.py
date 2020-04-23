#!/usr/bin/env python
# This will be refactored into proper suite, now just quick hack for
# testing.
import importlib
import os
import asyncio
import argparse
import json
import sofie_offer_marketplace as om
import time
import dateparser
from typing import List, Dict, Any
from datetime import datetime
from web3 import Web3, HTTPProvider
from web3.contract import ConciseContract
from sofie_offer_marketplace.ethereum import Web3Contract
from sofie_offer_marketplace.exceptions import UnknownMarketType
from sofie_offer_marketplace.core import register_marshaller

from .flower_marshaller import FlowerRequest, FlowerOffer


register_marshaller("eu.sofie-iot.offer-marketplace-demo.flower",
                    FlowerRequest, FlowerOffer)


class FallbackRequest(om.Request):
    def __init__(self,
                 request_id: int = None,
                 deadline: int = None,
                 is_pending: bool = None,
                 is_decided: bool = None,
                 is_open: bool = None,
                 is_closed: bool = None,
                 offers: List['om.Offer'] = [],
                 decided_offers: List['om.Offer'] = [],
                 **kwargs) -> None:
        super().__init__(request_id, deadline, is_pending, is_decided, is_open, is_closed, offers, decided_offers)

        self.unknown_extra = kwargs

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
        return "{} by {} ({}){:>6}{:>5}{}".format(
            str(self.unknown_extra), datetime.fromtimestamp(self.deadline).isoformat(), self.deadline,
            "PAST" if self.deadline < time.time() else "", self.stage_str, " DECIDED" if self.is_decided else "")

    @classmethod
    def from_data(cls,
                  request_id: int,
                  common: Dict[str, Any],
                  extra: List[Any] = [],
                  init_args: Dict[str, Any] = {}):
        init_args['unknown_extra'] = extra

        return super(FallbackRequest, cls).from_data(
            request_id, common, init_args=init_args)

    @classmethod
    def from_args(cls,
                  deadline: int,
                  args: List[str]):
        assert False, "cannot instantiate generic request from arguments"


class FallbackOffer(om.Offer):
    def __init__(self,
                 offer_id=None,
                 request_id=None,
                 author=None,
                 **kwargs) -> None:
        super().__init__(offer_id, request_id, author)

        self.unknown_extra = kwargs

    def __str__(self):
        return "{} (@{})".format(self.unknown_extra, self.author or "unset")

    @classmethod
    def from_data(cls,
                  offer_id: int,
                  common: Dict[str, Any],
                  extra: List[Any] = [],
                  init_args: Dict[str, Any] = {}):
        init_args['unknown_extra'] = extra

        return super(FallbackOffer, cls).from_data(
            offer_id, common, init_args=init_args)

    @classmethod
    def from_args(cls,
                  request_id: int,
                  args: List[str]):
        assert False, "cannot instantiate generic offer from arguments"


def get_parser():
    p = argparse.ArgumentParser()

    p.add_argument('--account', metavar='ACCOUNT',
                   help="""Account to use to access Ethereum (defaults to env.
                   variable MARKETPLACE_ACCOUNT)""")
    p.add_argument('--password', metavar='PASSWORD',
                   help="""Password to unlock the Ethereum account (defaults to
                   env. variable MARKETPLACE_ACCOUNT_PASSWORD, or '')""")
    p.add_argument('--contract', metavar='CONTRACT-ADDRESS',
                   help="""Address of the marketplace contract
                   (defaults to env. variable MARKETPLACE_CONTRACT)""")
    p.add_argument('--interface-file',
                   default='solidity/build/contracts/FlowerMarketPlace.json',
                   help="""Path to the marketplace contract
                   interface definition file (defaults to
                   'solidity/build/contracts/FlowerMarketPlace.json'""")
    p.add_argument('--manager', action='store_true')
    p.add_argument('--owner', action='store_true')
    p.add_argument('--override-type', type=str,
                   help="""Determines that which of the registered
                   types are the actual contract's type""")
    p.add_argument('--register', metavar='REGISTERED_ACCOUNT', action='append',
                   help="""Path to a package that includes a class named
                   'TypeMapping' that contains an attribute named
                   'type_mapping' which is a dictionary that maps the
                   type of the marketplace to the actual request and
                   offer classes (defaults to env.variable
                   REGISTERED_ACCOUNT).""")
    sp = p.add_subparsers(dest='command')

    rp = sp.add_parser("list-requests", aliases=['list'])

    arp = sp.add_parser("add-request")
    arp.add_argument('deadline', metavar='DEADLINE', nargs='?',
                     type=lambda v: int(dateparser.parse(v).timestamp()),
                     default=int(time.time()) + 3600,
                     help="""Request deadline, default in now + 1 hour,
                         uses `dateparser` so
                         things like 'tomorrow', 'in 3 weeks' and
                         '2020-02-01' work""")
    arp.add_argument('rparams', nargs=argparse.REMAINDER,
                     help="""You should enter the parameters which are needed
                     to make a request_class instance in a correct order.""")

    srp = sp.add_parser('show-request', aliases=["show"])
    srp.add_argument('request', metavar='REQUEST', type=int)

    drp = sp.add_parser('decide-request')
    drp.add_argument('request', metavar='REQUEST', type=int)

    aop = sp.add_parser("add-offer")
    aop.add_argument('request', metavar='REQUEST', type=int,
                     help='Request identifier')
    aop.add_argument('oparams', nargs=argparse.REMAINDER,
                     help="""You should enter the parameters which are needed
                     to make a offer_class instance in a correct order.""")

    # market info
    # decide request
    # add manager
    # remove manager
    # owner change
    # deploy contract too??

    p.set_defaults(
        command='list-requests',
        account=os.environ.get('MARKETPLACE_ACCOUNT'),
        contract=os.environ.get('MARKETPLACE_CONTRACT'),
        password=os.environ.get('MARKETPLACE_ACCOUNT_PASSWORD', ''),
        register=[
            t for t in os.environ.get('MARKETPLACE_TYPES', '').split(",")
            if t])
    return p


async def async_main():
    args = get_parser().parse_args()
    contract_interface = json.loads(open(args.interface_file).read())

    w3 = Web3()

    if args.account:
        w3.eth.defaultAccount = args.account
    elif not w3.eth.defaultAccount:
        if not w3.eth.accounts:
            assert False, "no account specified, and no default available"
        w3.eth.defaultAccount = w3.eth.accounts[0]

    w3.geth.personal.unlockAccount(w3.eth.defaultAccount, args.password, 1)

    c = Web3Contract(w3,
                     contract_address=args.contract,
                     contract_interface=contract_interface)
    for package_name in args.register:
        package = importlib.import_module(package_name)

        for name, (request_class, offer_class) in package.TypeMapping.type_mapping.items():
            register_marshaller(name, request_class, offer_class)

    m = om.Marketplace(
        contract=c,
        is_manager=args.manager,
        is_owner=args.owner,
        marketplace_type=args.override_type,
        fallback_request_class=FallbackRequest,
        fallback_offer_class=FallbackOffer
    )

    if m.request_class is FallbackRequest:
        print(f"Warning: Marketplace type {m.get_type()} does not map into a known request class, using fallback")

    if m.offer_class is FallbackOffer:
        print(f"Warning: Marketplace type {m.get_type()} does not map into a known offer class, using fallback")

    if args.command in ['list-requests', 'list']:
        for r in m.get_requests():
            print("#{:<4} {}".format(r.request_id, str(r)))

    elif args.command == 'add-request':
        request = m.request_class.from_args(deadline=args.deadline,
                                            args=args.rparams)
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
            # market SC is decision maker
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
  {}
""".format(request.request_id,
           datetime.fromtimestamp(request.deadline),
           " (PAST)" if request.deadline < time.time() else "",
           "Yes" if request.is_decided else "No",
           "Yes" if request.is_pending else "No",
           "Yes" if request.is_open else "No",
           "Yes" if request.is_closed else "No",
           request))

            if not request.offers:
                print("No offers")
            else:
                print("Offers:")

                for o in request.offers:
                    print("  #{:<4} {:<6} {}{}".format(
                        o.offer_id,
                        o.price,
                        o.author,
                        " (DECIDED)" if request.decided_offer and (
                                o.offer_id == request.decided_offer.offer_id) else ""))

    elif args.command == 'add-offer':
        assert m.offer_class is not FallbackOffer, \
            "The actual type of market is: {}. Fallbacks can not be used to do changes.".format(c_type)
        request = m.get_request(int(args.request))
        if request is None:
            print("Request {} does not exist".format(args.request))
        else:
            offer = m.offer_class.from_args(request_id=request.request_id, args=args.oparams)
            final_offer = await m.add_offer(offer)
            print(("Offer {} for request {} "
                   "added into block {}, {} gas used").format(
                final_offer, request.request_id,
                c.last_block_number, c.last_gas_used))
    else:
        assert False, "unhandled command {}".format(args.command)


def main():
    asyncio.get_event_loop().run_until_complete(async_main())
