import concurrent.futures
import types
import uuid
import requests
from flask import Flask, request
from flask_restful import Resource, Api, abort
import json

from .app import events, launch_event_filters, r


# APIs to implement:
# http:get:: /subscription/events/, OK
# http:post:: /subscription/, OK
# http:get:: /subscription/(string:id), OK
# http:put:: /subscription/(string:id), OK
# http:delete:: /subscription/(string:id), OK

SUBSCRIBED = False


class SubscriptionEvents(Resource):
    def get(self):
        """
        Lists events available for subscriptions
        """
        print("GET /subscription/events triggered...")
        return {
            'events': events
        }


class Subscribe(Resource):

    def post(self):
        """
        Subscribes to the specific event. E.g.
        {
            "event": "RequestAdded",
            "url": "https://mydomain.com/marketplace/callback/"
        }
        """

        global SUBSCRIBED
        if not SUBSCRIBED:
            launch_event_filters.delay(events)
            SUBSCRIBED = True

        request_json = request.get_json()
        # fetch event name and url
        if 'event' not in request_json or 'url' not in request_json:
            abort(400, error="'event' or 'url' parameter missing")
        event_name  = request_json['event']
        url = request_json['url']

        if not event_name in events:
            abort(400, error = "Event not found", message = event_name)
        
        # Create a new callback object
        subscription_id = str(uuid.uuid4())
        callback_data = {"event": event_name, "url": url} # JSON serializable

        # load subscriptions related data from redis
        subscriptions = json.loads(r.get('subscriptions').decode('utf-8'))
        event_subscriptions = json.loads(r.get('event_subscriptions').decode('utf-8'))

        # update in memory
        subscriptions[subscription_id] = callback_data
        if event_name not in event_subscriptions:
            event_subscriptions[event_name] = [subscription_id]
        else:
            event_subscriptions[event_name].append(subscription_id)

        # persist in redis
        r.set("subscriptions", json.dumps(subscriptions))
        r.set("event_subscriptions", json.dumps(event_subscriptions))
        
        #return {"event": event_name, "url": url, "id": str(subscription_id)}
        return {"id": subscription_id}


class SubscriptionOperations(Resource):
    def get(self, subscription_id):
        """
        Returns details for the subscription with a given id
        """

        subscriptions = json.loads(r.get('subscriptions').decode('utf-8'))

        if subscription_id not in subscriptions.keys():
            abort(400, error = "Subsription not found")
        subscription = subscriptions[subscription_id]
        
        return {"event": subscription['event'], "url": subscription['url']}


    def put(self, subscription_id):
        """
        Updates an existing subscription, either new event name or new URL must be provided
        """
        
        subscriptions = json.loads(r.get('subscriptions').decode('utf-8'))
        event_subscriptions = json.loads(r.get('event_subscriptions').decode('utf-8'))

        if subscription_id not in subscriptions.keys():
            abort(400, error = "Subsription not found")

        if not request.is_json:
            abort(400, error = "Parameters should given in JSON format")
            
        data = request.get_json()
        print(f"data put here: {data}")
        if ('event' not in data.keys()) and ('url' not in data.keys()):
            abort(400, error="Either 'event' or 'url' parameter is required")


        if 'event' in data.keys():
            # update callback event
            if not data['event'] in events:
                abort(400, error = "Event not found", message = data['event'])
            
            # remove the id from origianl event type
            event_original = subscriptions[subscription_id]['event']
            event_subscriptions[event_original].remove(subscription_id)

            subscriptions[subscription_id]['event'] = data['event']

            # add the id under new event type
            if data['event'] not in event_subscriptions:
                event_subscriptions[data['event']] = [subscription_id]
            else:
                event_subscriptions[data['event']].append(subscription_id)
            
        if 'url' in data.keys():
            # update callback URL
            subscriptions[subscription_id]['url'] = data['url']

        print(subscriptions)
        r.set('subscriptions', json.dumps(subscriptions))
            
            
    def delete(self, subscription_id):
        """
        Deletes subscription with a given id
        """
        
        subscriptions = json.loads(r.get('subscriptions').decode('utf-8'))

        if subscription_id not in subscriptions.keys():
            abort(400, error = "Subsription not found")

        del subscriptions[subscription_id]

        r.set('subscriptions', json.dumps(subscriptions))

        return "", 204


# # For debugging purposes
# class Subscriptions(Resource):
#     def get(self):
#         """
#         Lists all active subscriptions 
#         """
#         subscriptions = json.loads(r.get('subscriptions').decode('utf-8'))
#         return_dict = {}
        
#         for key, value in subscriptions.items():
#             return_dict[key] = [value['event'], value['url']]
#         return return_dict
