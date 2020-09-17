import json
import sys
from datetime import datetime
from web3 import Web3

from sofie_offer_marketplace.ethereum import Web3Contract


def parse_ethereum(parser, network="marketplace"):
  c = parser[network]

  url = c['url']
  contract_address = Web3.toChecksumAddress(c['contract'])
  minter = Web3.toChecksumAddress(c['minter'])

  with open(c['artifact']) as json_file:
    artifact = json.load(json_file)

  return url, contract_address, minter, artifact


def get_web3contract(url, contract_address, minter, artifact):
    protocol = url.split(":")[0].lower()

    # create the web3 instance
    if protocol in ("http", "https"):
        w3 = Web3(Web3.HTTPProvider(url))
    elif protocol in ("ws", "wss"):
        w3 = Web3(Web3.WebsocketProvider(url))
    else:
        raise ValueError("Unsupported Web3 protocol")

    # instantiate the web3 contract for interaction
    return Web3Contract(
        web3=w3,
        contract_address=contract_address,
        contract_interface=artifact,
        minter=minter)


def get_request_response(marketplace, request_id):
    status, deadline, stage, request_maker = marketplace.contract.functions.getRequest(
        request_id).call()
    # undefined request id
    if status == 2:
        return
    extra = marketplace.get_request_extra(request_id)

    is_decided = marketplace.status1(
        marketplace.contract.functions.isRequestDecided(request_id).call())
    if is_decided:
        state = "decided"
        decision_time = marketplace.status1(
            marketplace.contract.functions.getRequestDecisionTime(request_id).call())
        decision_time = str(datetime.fromtimestamp(decision_time))
    else:
        state = ("pending", "open", "closed")[stage]
        decision_time = None

    offer_ids = marketplace.status1(
        marketplace.contract.functions.getRequestOfferIDs(request_id).call())

    decided_ids = marketplace.status1(marketplace.contract.functions.getRequestDecision(
        request_id).call()) if is_decided else []

    return {
        "id": request_id,
        "from": request_maker,
        "deadline": str(datetime.fromtimestamp(deadline)),
        "extra": extra,
        "state": state,
        "offers": offer_ids,
        "decision": decided_ids,
        "decided": decision_time
    }


def get_offer_response(marketplace, offer_id):
    offer = marketplace.get_offer(offer_id)
    if not offer:
        return
    request_id = offer['request_id']
    author = offer['author']
    stage = offer['stage']
    state = ("pending", "open", "closed")[stage]

    extra = marketplace.get_offer_extra(offer_id) if state != "pending" else None

    return {
        "id": offer_id,
        "request_id": request_id,
        "author": author,
        "extra": extra,
        "state": state
    }


def parse_events(artifact: dict):
    """
    Parses events from the compiled contract, 
    and stores them in the global events variable.
    
    :param json artifact: the artifact json object compiled contract loaded
    """

    events = [] # list of event names
    event_input_types = {} # map event name to tuple of input types

    
    for entry in artifact['abi']:
        if entry['type'] == 'event':
            event_name = entry['name']
            events.append(event_name)
            event_input_types[event_name] = (input['type'] for input in entry['inputs'])

    return events, event_input_types
