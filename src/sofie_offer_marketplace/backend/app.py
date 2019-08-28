from flask import Flask
from flask_restful import Resource, Api, abort

app = Flask(__name__)
api = Api(app)


class Request(Resource):
    def get(self, request_id):
        abort(501, message="Not implemented yet")

    def put(self, request_id):
        abort(501, message="Not implemented yet")

    def delete(self, request_id):
        abort(501, message="Not implemented yet")


class Offer(Resource):
    def get(self, offer_id):
        abort(501, message="Not implemented yet")

    def put(self, offer_id):
        abort(501, message="Not implemented yet")

    def delete(self, offer_id):
        abort(501, message="Not implemented yet")


class Information(Resource):
    def get(self):
        abort(501, message="Not implemented yet")


class Requests(Resource):
    def get(self):
        abort(501, message="Not implemented yet")

    def post(self):
        abort(501, message="Not implemented yet")


class Offers(Resource):
    def get(self):
        abort(501, message="Not implemented yet")

    def post(self):
        abort(501, message="Not implemented yet")


class OfferExtraRegistration(Resource):
    def post(self):
        abort(501, message="Not implemented yet")


class RequestExtraRegistration(Resource):
    def post(self):
        abort(501, message="Not implemented yet")


api.add_resource(Request, '/request/<int:request_id>')
api.add_resource(Offer, '/offer/<int:offer_id>')
api.add_resource(Information, '/info')
api.add_resource(Requests, '/request')
api.add_resource(Offers, '/offer')
api.add_resource(OfferExtraRegistration, '/offer/register')
api.add_resource(RequestExtraRegistration, '/request/register')
