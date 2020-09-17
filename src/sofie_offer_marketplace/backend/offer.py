from flask import Flask, request
from flask_restful import Resource, abort

from .app import marketplace
from .utils import get_offer_response


class Offer(Resource):
    def get(self, offer_id):
        res = get_offer_response(marketplace, offer_id)
        if res:
            return res
        abort(404, message="Not found, undefined object")

    def put(self, offer_id):
        abort(501, message="Not implemented yet")

    def delete(self, offer_id):
        abort(501, message="Not implemented yet")



class OfferExtraRegistration(Resource):
    def post(self):
        request_json = request.get_json()
        offer_id  = request_json['offer_id']
        extra = request_json['extra']

        if not marketplace.get_offer(offer_id):
            abort(400, message="Bad request")

        res = marketplace.add_offer_extra(offer_id, extra)
        
        if res:
            return {"offer_id": offer_id}
        else:
            abort(400, message="Bad request")


class Offers(Resource):
    def get(self):
        # collect offer ids
        offer_ids = []
        request_ids = marketplace.get_request_ids()
        for request_id in request_ids:
            request = marketplace.get_request(request_id)
            offer_ids += request['offer_ids']
        
        # collect offers
        offers = []
        # TODO: add logic for ids only option
        for offer_id in offer_ids:
            offers.append(get_offer_response(marketplace, offer_id))
        return {'offers': offers}

    def post(self):
        request_id = request.get_json()["request_id"]

        is_decided = marketplace.status1(
            marketplace.contract.functions.isRequestDecided(request_id).call())
        if is_decided:
            abort(400, message="Bad request, the decision has been made")

        offer_id = marketplace.add_offer(request_id)

        if offer_id >= 0:
            return {
                "offer_id": offer_id
            }
        else:
            abort(400, message="Bad request")