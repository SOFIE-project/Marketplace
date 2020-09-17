import pytest
import os
from configparser import ConfigParser
from argparse import Namespace  # evil

import sofie_offer_marketplace as om
from sofie_offer_marketplace.ethereum import Web3Contract
import sofie_offer_marketplace.backend as be
from sofie_offer_marketplace.backend.utils import parse_ethereum, get_web3contract
from .utils import MockContract, MockRequest, MockOffer

config_file = os.getenv("MARKETPLACE_CONFIG", "local-config.cfg")

@pytest.fixture
def contract():
    return MockContract()


@pytest.fixture
def web3contract():
    """have the web3 contract instance
    """
    parser = ConfigParser()
    parser.read(config_file) 

    url, contract_address, minter, artifact = parse_ethereum(parser)
    return get_web3contract(url, contract_address, minter, artifact)


@pytest.fixture
def marketplace(contract):
    return om.Marketplace(contract=contract,
                          fallback_request_class=MockRequest,
                          fallback_offer_class=MockOffer)


@pytest.fixture
def client():
    be.app.config['TESTING'] = True
    client = be.app.test_client()
    return client
