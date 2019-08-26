import pytest
from .utils import MockContract, MockRequest, MockOffer
import sofie_offer_marketplace as om
from sofie_offer_marketplace.exceptions import \
    ManagerAccessRequired, OwnerAccessRequired


@pytest.mark.asyncio
async def test_access_failures():
    m = om.Marketplace(MockContract(), is_owner=False, is_manager=False, fallback_request_class=MockRequest,
                       fallback_offer_class=MockOffer)

    with pytest.raises(ManagerAccessRequired):
        await m.add_request(MockRequest())

    with pytest.raises(ManagerAccessRequired):
        await m.decide_request(MockRequest(request_id=1),
                               MockOffer(request_id=1, offer_id=2))

    with pytest.raises(ManagerAccessRequired):
        await m.add_offerer("address")

    with pytest.raises(ManagerAccessRequired):
        await m.remove_offerer("address")

    with pytest.raises(OwnerAccessRequired):
        await m.add_manager("address")

    with pytest.raises(OwnerAccessRequired):
        await m.remove_manager("address")


@pytest.mark.asyncio
async def test_access_manager():
    m = om.Marketplace(MockContract(), is_owner=False, is_manager=True,
                       fallback_request_class=MockRequest,
                       fallback_offer_class=MockOffer)

    request = await m.add_request(MockRequest())

    assert request is not None
    assert request.request_id is not None

    offer = await m.add_offer(MockOffer(request_id=request.request_id))
    assert offer is not None
    assert offer.offer_id is not None
    assert offer.request_id == request.request_id

    result = await m.decide_request(request, [offer])
    assert result is True

    # await m.add_offerer("address")
    # await m.remove_offerer("address")

    with pytest.raises(OwnerAccessRequired):
        await m.add_manager("address")

    with pytest.raises(OwnerAccessRequired):
        await m.remove_manager("address")


@pytest.mark.xfail
@pytest.mark.asyncio
async def test_access_owner():
    m = om.Marketplace(MockContract(), is_owner=True, is_manager=False)

    with pytest.raises(ManagerAccessRequired):
        await m.add_request(MockRequest())

    with pytest.raises(ManagerAccessRequired):
        await m.decide_request(MockRequest(), MockOffer())

    with pytest.raises(ManagerAccessRequired):
        await m.add_offerer("address")

    with pytest.raises(ManagerAccessRequired):
        await m.remove_offerer("address")

    with pytest.raises(OwnerAccessRequired):
        await m.add_manager("address")

    with pytest.raises(OwnerAccessRequired):
        await m.remove_manager("address")
