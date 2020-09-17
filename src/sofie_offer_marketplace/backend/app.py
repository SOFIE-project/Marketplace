import os
from configparser import ConfigParser
import redis
import json
from datetime import datetime
from flask import Flask
from celery import Celery
from collections import defaultdict
from web3 import Web3
import time
from flask_restful import Resource, Api, abort
import requests

from sofie_offer_marketplace.backend.utils import parse_ethereum, get_web3contract, parse_events

""" Parsing configurations
"""
parser = ConfigParser()
configuration_file = os.getenv("MARKETPLACE_CONFIG", "local-config.cfg")
parser.read(configuration_file)

url, contract_address, minter, artifact = parse_ethereum(parser)

# prepare marketplace instance for the resources
marketplace = get_web3contract(url, contract_address, minter, artifact)

# prepare events for callback resources
events, event_input_types = parse_events(artifact)

# create filter for all events
event_filters = {} # key: event name, value: event filter

hash2event = {} # key: string of event signature hash, value: event name

# stores all registered subscriptions:
#  key: str(uuid4), value: {"event": event_name, "url": url}
subscriptions: dict = {}

# stores mapping from event to subscriptipns list
event_subscriptions: dict = {}

for event_name in events:
    input_types = event_input_types[event_name]
    event_signature = event_name + '(' + ','.join(input_types) + ')'

    event_signature_hash = Web3.keccak(text=event_signature).hex()
    hash2event[str(event_signature_hash)] = event_name

    event_filter = marketplace.web3.eth.filter({
        "address": contract_address,
        "topics": [event_signature_hash],
    })
    event_filters[event_name] = event_filter

# store subscriptions, event_subscriptions into redis
redis_server = os.getenv("REDIS_HOST", "localhost")
r = redis.Redis(host=redis_server, port=6379, db=0)

r.set('subscriptions', json.dumps(subscriptions))
r.set('event_subscriptions', json.dumps(event_subscriptions))


""" Have Flask application
"""
app = Flask(__name__)

""" Wrap for celery
"""
def make_celery(app):
    celery = Celery(
        app.import_name,
        backend=app.config['CELERY_RESULT_BACKEND'],
        broker=app.config['CELERY_BROKER_URL']
    )
    celery.conf.update(app.config)

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask
    return celery

app.config.update(
    CELERY_BROKER_URL='redis://localhost:6379',
    CELERY_RESULT_BACKEND='redis://localhost:6379'
)

celery = make_celery(app)

def call_subscribers(event_name: str, payload: str = '', subs: list = []):
    """
    Calls callbacks which are registered to this event
    """
    # construct request object used for callbacks
    callback_request = {}
    callback_request['event'] = event_name
    callback_request['payload'] = payload # str, json serializable

    # prepare subscription data
    subscriptions = json.loads(r.get('subscriptions').decode('utf-8'))

    # invoke callbacks of each subscriber
    for s_id in subs:
        print(f"Invoking callback for {s_id}...")
        s_url = subscriptions[s_id]['url']
        call_subscriber(s_url, callback_request)


def call_subscriber(url: str, callback_request: dict):
    res = requests.post(url, json=callback_request)

    if res.status_code < 200 or res.status_code >= 300:
        print("Error calling callback:", url, ", Status code:", res.status_code)
    else:
        r.set('cb_response', json.dumps({'timestamp': str(datetime.now()), 'data': str(res.status_code)})) # this is only used for testing

        print(f"Callback at {url} invoked, with response: {res.status_code, res.json()}")


def trigger_callbacks_by_event(event_name, payload=''):

    print(f"triggering event: {event_name}...")

    # load subscriptions related data from redis
    event_subscriptions = json.loads(r.get('event_subscriptions').decode('utf-8'))
    if event_name not in event_subscriptions:
        print("no subscription")
    else:
        subs = event_subscriptions[event_name]
        call_subscribers(event_name, payload, subs)


@celery.task()
def launch_event_filters(events):
    while True:
        captured = False
        for event in events:
            # listening for events
            entries = event_filters[event].get_new_entries()
            if entries:
                captured = True
                for entry in entries:
                    # parse entry for event name & data payload
                    signature_hash = str(entry['topics'][0].hex())
                    data_payload = entry['data'] # str
                    event_name = hash2event[signature_hash]
                    try:
                        trigger_callbacks_by_event(event_name, data_payload)
                    except Exception as e:
                        print(e)
                        pass

        if not captured:
            print("no events emitted...")
        time.sleep(5)


""" Wrap for Flask RESTful
"""

from sofie_offer_marketplace.backend.information import Information
from sofie_offer_marketplace.backend.request import RequestState, Request, RequestExtraRegistration, Requests
from sofie_offer_marketplace.backend.offer import Offer, OfferExtraRegistration, Offers
from sofie_offer_marketplace.backend.callbacks import SubscriptionEvents, Subscribe, SubscriptionOperations

# wrap for Flask RESTful APIs
api = Api(app)
        
# API end points
# information related
api.add_resource(Information, '/info')

# request related
api.add_resource(Request, '/request/<int:request_id>')
api.add_resource(RequestExtraRegistration, '/request/register')
api.add_resource(Requests, '/request')

# offer related
api.add_resource(Offer, '/offer/<int:offer_id>')
api.add_resource(Offers, '/offer')
api.add_resource(OfferExtraRegistration, '/offer/register')

# event callbacks related
api.add_resource(SubscriptionEvents, '/subscription/events')
api.add_resource(Subscribe, '/subscription')
api.add_resource(SubscriptionOperations, '/subscription/<string:subscription_id>')

# # for debugging, TODO: remove these before release
# api.add_resource(Subscriptions, "/subscriptions")


""" Manual run as main script
"""
if __name__ == "__main__":
    app.run(debug=True)
