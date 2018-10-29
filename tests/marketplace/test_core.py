import pytest
import sofie_offer_marketplace as om
from .utils import MockRequest, MockOffer


def test_creation(contract):
    m = om.Marketplace(contract=contract)
    assert m is not None


def test_get_requests_empty(marketplace, contract):
    print(marketplace.get_requests())
    print(contract.requests)

    assert len(marketplace.get_requests()) == 0


def test_get_requests_empty_specific(marketplace, contract):
    assert marketplace.get_request(0) is None


def assert_equal(a: MockRequest, b: MockRequest) -> None:
    for f in ('quantity', 'type', 'request_id',
              'is_open', 'is_closed', 'is_pending', 'is_decided'):
        assert getattr(a, f) == getattr(b, f), \
            "field {} differs ({!r} vs {!r})".format(
                f, getattr(a, f), getattr(b, f))


def test_get_requests_nonempty(marketplace, contract):
    r1, r2 = MockRequest(1), MockRequest(2)
    contract.requests = [r1, r2]
    assert {r.request_id for r in marketplace.get_requests()} == {1, 2}

    print(r1, marketplace.get_request(1))

    assert_equal(marketplace.get_request(1), r1)
    assert_equal(marketplace.get_request(2), r2)
    assert marketplace.get_request(3) is None


@pytest.mark.asyncio
async def test_add_request(marketplace, contract, mocker):
    marketplace.is_manager = True
    mocker.spy(contract, 'add_request')
    mocker.spy(contract, 'add_request_extra')

    r = MockRequest(quantity=9, type=3, deadline=5321)
    mocker.spy(r, 'marshal_extra')

    result = await marketplace.add_request(r)
    print(r, "->", result)

    assert result.request_id is not None

    r.marshal_extra.assert_called_once_with()
    contract.add_request.assert_called_once_with(5321)
    contract.add_request_extra.assert_called_with(result.request_id, [9, 3])


@pytest.mark.asyncio
async def test_add_offer(marketplace, contract, mocker):
    contract.requests = [MockRequest(1)]

    mocker.spy(contract, 'add_offer')
    mocker.spy(contract, 'add_offer_extra')

    o = MockOffer(request_id=10, price=91, author="nobody")
    mocker.spy(o, 'marshal_extra')

    contract.counter = 100
    result = await marketplace.add_offer(o)
    assert result.offer_id is not None

    o.marshal_extra.assert_called_once_with()
    contract.add_offer.assert_called_once_with(10)
    contract.add_offer_extra.assert_called_once_with(101, [91])
