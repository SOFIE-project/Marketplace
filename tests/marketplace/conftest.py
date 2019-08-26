import pytest
import sofie_offer_marketplace as om
from .utils import MockContract, MockRequest, MockOffer
from argparse import Namespace  # evil


@pytest.fixture
def contract():
    return MockContract()


@pytest.fixture
def marketplace(contract):
    return om.Marketplace(contract=contract,
                          fallback_request_class=MockRequest,
                          fallback_offer_class=MockOffer)
