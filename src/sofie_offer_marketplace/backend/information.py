from flask_restful import Resource

from .app import marketplace


class Information(Resource):
    def get(self):
        marketplace_type = marketplace.get_type()
        contract_address = marketplace.contract.address

        network_id = marketplace.web3.net.version
        return {
            "type": marketplace_type,
            "contract": {
                "address": contract_address,
                "network": network_id
            }
        }
        