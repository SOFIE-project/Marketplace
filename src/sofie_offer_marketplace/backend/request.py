from flask import Flask, request
from flask_restful import Resource, abort

from .app import marketplace
from .utils import get_request_response


class RequestState:
    Pending = "pending"
    Open = "open"
    Closed = "closed"
    Decided = "decided"


class Request(Resource):
    def get(self, request_id):
        res = get_request_response(marketplace, request_id)
        if res:
            return res
        abort(404, message="Not found, undefined object")

    def put(self, request_id):
        if not marketplace.get_request(request_id):
            abort(400, message="Bad request, not defined request id")

        is_decided = marketplace.status1(
            marketplace.contract.functions.isRequestDecided(request_id).call())
        if is_decided:
            abort(400, message="Bad request, the decision has been made")

        request_json = request.get_json()
        try:
            assert 'state' in request_json
        except AssertionError:
            abort(400, message="Bad request")

        state = request_json['state']
        try:
            assert state in (RequestState.Closed, RequestState.Decided)
        except AssertionError:
            abort(400, message="Bad request")

        # close a request
        if state == RequestState.Closed:
            isclosed = marketplace.close_request(request_id)
            if isclosed:
                return {"state": RequestState.Closed}
            else:
                abort(401, "Failed, authorization required")
        # decide a request
        else:
            try:
                assert 'decision' in request_json
                decision = request_json['decision']
                assert isinstance(decision, list)
                for item in decision:
                    assert isinstance(item['id'], int)
                selected_offer_ids = [item['id'] for item in decision]
            except AssertionError:
                abort(400, message="Bad request")

            isdecided = marketplace.decide_request(request_id, selected_offer_ids)
            
            if isdecided:
                return {"state": RequestState.Decided}
            else:
                abort(401, "Failed, authorization required")

    def delete(self, request_id):
        res = marketplace.delete_request(request_id)
        if res == True:
            return "Deleted", 204
        else: 
            abort(400, message="Bad request")


class RequestExtraRegistration(Resource):
    def post(self):
        request_json = request.get_json()
        request_id = request_json['request_id']
        extra = request_json['extra']
        try:
            assert isinstance(extra, list)
        except AssertionError:
            abort(400, message="Bad request")
        
        is_decided = marketplace.status1(
            marketplace.contract.functions.isRequestDecided(request_id).call())
        if is_decided:
            abort(400, message="Bad request, the decision has been made")

        res = marketplace.add_request_extra(request_id, extra)
        if res:
            return
        else:
            abort(400, message="Bad request")


class Requests(Resource):
    def get(self):
        # parse query parameters
        state_filter = request.args.get('state')
        if not state_filter:
            state_filter = "open" # default to open
        # TODO: add logic for ids only option

        # collect requests
        requests = []
        open_requests_ids = marketplace.get_open_request_ids()
        closed_requests_ids = marketplace.get_closed_request_ids()

        if state_filter == "closed":
            request_ids = closed_requests_ids
        elif state_filter == "open":
            request_ids = open_requests_ids
        else: # "all" or "decided"
            request_ids = open_requests_ids + closed_requests_ids

        if state_filter == "decided":
            for request_id in request_ids:
                request_response = get_request_response(marketplace, request_id)
                if request_response['state'] == "decided":
                    requests.append(request_response)
        else:
            for request_id in request_ids:
                request_response = get_request_response(marketplace, request_id)
                requests.append(request_response) 
        return {"requests": requests}

    def post(self):
        deadline = int(request.get_json()['deadline']) # 2000000000
        request_id = marketplace.add_request(deadline)
        if request_id >= 0:
            return {
                "id": request_id
            }
        else:
            abort(401, message="Failed, authorization required")