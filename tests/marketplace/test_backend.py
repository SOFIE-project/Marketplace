from web3 import Web3

from .utils import _check_existence, _check_request_spec, _check_offer_spec


request_id_g = None
offer_id_g = None

# 1. Extract basic information
def test_get_information(client, web3contract):
    # GET /info
    res = client.get('/info')

    assert res.status_code == 200

    info = res.get_json()
    assert 'type' in info
    assert info['type'] == "eu.sofie-iot.offer-marketplace-demo.flower"
    assert 'contract' in info
    contract = info['contract']
    assert contract['address'] == web3contract.contract.address
    assert contract['network'] == web3contract.web3.net.version


# 2.a Try to add request without authorization
def test_add_request(client, web3contract):
    # POST /request
    res = client.post('/request', json={
        "deadline": 2000000001
    })
    assert res.status_code == 200
    res_obj = res.get_json()
    request_id = res_obj["id"]

    # GET /request/:id
    res = client.get(f'/request/{request_id}')

    assert res.status_code == 200

    res_obj = res.get_json()
    _check_request_spec(res_obj, request_id, web3contract)
    assert res_obj['state'] == "pending", "the new request should've been pending"


# 2.b Manipulate with request: close and delete
def test_manipulate_request(client, web3contract):
    # POST /request
    res = client.post('/request', json={
        "deadline": 2000000002
    })
    assert res.status_code == 200
    res_obj = res.get_json()
    request_id = res_obj["id"]

    # GET /request/:id
    res = client.get(f'/request/{request_id}')

    assert res.status_code == 200

    res_obj = res.get_json()
    _check_request_spec(res_obj, request_id, web3contract)
    assert res_obj['state'] == "pending", "the new request should've been pending"

    # PUT /request/:id (close)
    res = client.put(f'/request/{request_id}', json={
        "state": "closed"
    })

    assert res.status_code == 200
    res_obj = res.get_json()
    assert res_obj['state'] == "closed", "the request should've been closed"

    # GET /request (filter closed ones)
    res = client.get('/request', query_string={
        "state": "closed"
    })

    assert res.status_code == 200
    res_obj = res.get_json()
    open_requests = res_obj['requests']
    
    assert _check_existence(request_id, open_requests), "the open one should be in the list of all open"

    # DELETE /request/:id
    res = client.delete(f'/request/{request_id}')
    assert res.status_code == 204

    # GET /request/:id
    res = client.get(f'/request/{request_id}')
    assert res.status_code == 404, "the deleted ond should not be found"


# 3.a Create and open a valid request
def test_open_valid_request(client, web3contract):
    # POST /request
    res = client.post('/request', json={
        "deadline": 2000000003
    })
    assert res.status_code == 200
    res_obj = res.get_json()
    request_id = res_obj["id"]

    global request_id_g
    request_id_g = request_id

    # GET /request
    res = client.get(f'/request/{request_id}')

    assert res.status_code == 200

    res_obj = res.get_json()
    _check_request_spec(res_obj, request_id, web3contract)
    assert res_obj['state'] == "pending", "the new request should've been pending"

    # POST /request/register
    res = client.post('/request/register', json={
        "request_id": request_id,
        "extra": [1, 1]
    })
    assert res.status_code == 200

    # try again with the same
    res = client.post('/request/register', json={
        "request_id": request_id,
        "extra": [1, 1]
    })
    assert res.status_code == 200

    # GET /request/:id
    res = client.get(f'/request/{request_id}')
    assert res.status_code == 200
    res_obj = res.get_json()
    _check_request_spec(res_obj, request_id, web3contract)
    assert res_obj['state'] == "open", "the new valid request should be open"

    # GET /request
    res = client.get('/request', query_string={
        "state": "open"
    })

    assert res.status_code == 200
    res_obj = res.get_json()
    closed_requests = res_obj['requests']
    
    assert _check_existence(request_id, closed_requests), "the closed one should be in the list of all closed"


# 3.b Add an empty offer
def test_add_offer(client, web3contract):
    # POST /offer
    res = client.post('/offer', json={
        "request_id": request_id_g
    })

    assert res.status_code == 200

    res_obj = res.get_json()
    offer_id = res_obj["offer_id"]

    # GET /offer/:id
    res = client.get(f'/offer/{offer_id}')
    assert res.status_code == 200
    
    res_obj = res.get_json()
    print(res_obj)
    
    _check_offer_spec(res_obj, offer_id, web3contract)


# 3.c Have valid offers
def test_submit_valid_offer(client, web3contract):
    # POST /offer
    res = client.post('/offer', json={
        "request_id": request_id_g
    })

    assert res.status_code == 200

    res_obj = res.get_json()
    offer_id = res_obj["offer_id"]

    global offer_id_g
    offer_id_g = offer_id

    # POST /offer/rigister
    res = client.post('/offer/register', json={
        "offer_id": offer_id,
        "extra": [42]
    })

    assert res.status_code == 200

    res_obj = res.get_json()
    assert res_obj['offer_id'] == offer_id

    # GET /offer/:id
    res = client.get(f'/offer/{offer_id}')
    assert res.status_code == 200
    
    res_obj = res.get_json()
    print(res_obj)
    
    _check_offer_spec(res_obj, offer_id, web3contract)

    # have another offer
    # POST /offer
    res = client.post('/offer', json={
        "request_id": request_id_g
    })

    assert res.status_code == 200

    res_obj = res.get_json()
    offer_id = res_obj["offer_id"]

    # POST /offer/rigister
    res = client.post('/offer/register', json={
        "offer_id": offer_id,
        "extra": [38]
    })

    assert res.status_code == 200

    res_obj = res.get_json()
    assert res_obj['offer_id'] == offer_id

    # POST /offer/rigister given a invalid offer_id
    res = client.post('/offer/register', json={
        "offer_id": offer_id + 999,
        "extra": [38]
    })

    assert res.status_code == 400

    # GET /offer/:id
    res = client.get(f'/offer/{offer_id}')
    assert res.status_code == 200
    
    res_obj = res.get_json()
    print(res_obj)
    
    _check_offer_spec(res_obj, offer_id, web3contract)

    # GET /offer
    res = client.get('/offer')
    assert res.status_code == 200

    res_obj = res.get_json()
    assert 'offers' in res_obj
    offers = res_obj['offers']
    assert isinstance(offers, list) == True
    for offer in offers:
        _check_offer_spec(offer, offer['id'], web3contract)

    assert _check_existence(offer_id_g, offers)
    assert _check_existence(offer_id, offers)


# 4 Test request decision
def test_request_decision(client, web3contract):
    # PUT /request/id (decide)
    res = client.put(f'/request/{request_id_g}', json={
        "state": "decided",
        "decision": [{
            "id": offer_id_g
        }]
    })

    assert res.status_code == 200
    res_obj = res.get_json()
    assert res_obj['state'] == "decided", "the request should've been decided"

    # GET /offer/id
    res = client.get(f'/offer/{offer_id_g}')
    assert res.status_code == 200
    
    res_obj = res.get_json()
    
    _check_offer_spec(res_obj, offer_id_g, web3contract)

    # GET /offer
    res = client.get('/offer')
    assert res.status_code == 200

    res_obj = res.get_json()
    assert 'offers' in res_obj
    offers = res_obj['offers']
    assert isinstance(offers, list) == True
    for offer in offers:
        _check_offer_spec(offer, offer['id'], web3contract)

    assert _check_existence(offer_id_g, offers)

    # GET /request/:id
    res = client.get(f'/request/{request_id_g}')
    assert res.status_code == 200

    res_obj = res.get_json()
    _check_request_spec(res_obj, request_id_g, web3contract)

    assert res_obj['state'] == "decided", "the request should have been decided"

    # try again with the request registration, when decision has been made
    res = client.post('/request/register', json={
        "request_id": request_id_g,
        "extra": [1, 1]
    })
    assert res.status_code == 400

    # try again with offer post, when decistion has been made
    res = client.post('/offer', json={
        "request_id": request_id_g
    })

    assert res.status_code == 400

    # GET /request (filter decided ones)
    res = client.get('/request', query_string={
        "state": "decided"
    })

    assert res.status_code == 200
    res_obj = res.get_json()
    decided_requests = res_obj['requests']
    
    assert _check_existence(request_id_g, decided_requests), "the targeted request should be in the list of all decided ones"
    


# def test_set_up(web3contract):
#     # ensure one valid request added at least
#     request_id = web3contract.add_request(1756080000)
#     web3contract.add_request_extra(request_id, [1, 1])

#     assert True
    

# def test_get_request(client, web3contract):
#     requests_count = len(web3contract.get_request_ids())

#     request_id = web3contract.add_request(1756090000)
#     web3contract.add_request_extra(request_id, [2, 2])
    
#     # collect requests
#     assert len(web3contract.get_request_ids()) == requests_count + 1
#     requests_count += 1

#     # GET /request/:id
#     res = client.get(f'/request/{request_id}')
#     assert res.status_code == 200

#     res_obj = res.get_json()
#     print(res_obj)

#     _check_request_spec(res_obj, request_id, web3contract)


# def test_put_request(client):
#     res = client.put('/request/1')
#     assert res.status_code == 501


# def test_delete_request(client):
#     res = client.delete('/request/1')
#     assert res.status_code == 501


# def test_get_offer(client, web3contract):
#     # add a valid request
#     request_id = web3contract.add_request(1601510400)
#     web3contract.add_request_extra(request_id, [3, 3])

#     # add valid offers for the request above
#     offer_id = web3contract.add_offer(request_id)
#     web3contract.add_offer_extra(offer_id, [99])
    
#     # GET /offer/:id
#     res = client.get(f'/offer/{offer_id}')
#     assert res.status_code == 200
    
#     res_obj = res.get_json()
#     print(res_obj)
    
#     _check_offer_spec(res_obj, offer_id, web3contract)


# def test_get_offers(client, web3contract):
#     # GET /offer
#     res = client.get('/offer')
#     assert res.status_code == 200

#     res_obj = res.get_json()
#     assert 'offers' in res_obj
#     offers = res_obj['offers']
#     assert isinstance(offers, list) == True
#     for offer in offers:
#         _check_offer_spec(offer, offer['id'], web3contract)



# def test_put_offer(client):
#     res = client.put('/offer/1')
#     assert res.status_code == 501


# def test_delete_offer(client):
#     res = client.delete('/offer/1')
#     assert res.status_code == 501


# def test_get_requests(client, web3contract):
#     req_ids = web3contract.get_request_ids()
#     requests_count = len(req_ids)

#     # GET /request
#     res = client.get('/request')

#     assert res.status_code == 200

#     res_obj = res.get_json()
#     print(res_obj)

#     assert 'requests' in res_obj
#     requests = res_obj['requests']

#     assert isinstance(requests, list) == True
#     assert len(requests) == requests_count
#     for i, request in enumerate(requests):
#         request_id = req_ids[i]
#         _check_request_spec(request, request_id, web3contract)

# def test_post_requests(client):
#     res = client.post('/request')
#     assert res.status_code == 501


# def test_post_offers(client):
#     res = client.post('/offer')
#     assert res.status_code == 501


# def test_post_offer_extra_registration(client):
#     res = client.post('/offer/register')
#     assert res.status_code == 501


# def test_post_request_extra_registration(client):
#     res = client.post('/request/register')
#     assert res.status_code == 501


# def test_offer_invalid_methods(client):
#     # test_post_request
#     res = client.post('/request/1')
#     assert res.status_code == 405

#     # test_post_offer
#     res = client.post('/offer/1')
#     assert res.status_code == 405

#     # test_post_information
#     res = client.post('/info')
#     assert res.status_code == 405

#     # test_put_information
#     res = client.put('/info')
#     assert res.status_code == 405

#     # test_delete_information
#     res = client.delete('/info')
#     assert res.status_code == 405

#     # test_put_requests
#     res = client.put('/request')
#     assert res.status_code == 405

#     # test_delete_requests
#     res = client.delete('/request')
#     assert res.status_code == 405

#     # test_put_offers
#     res = client.put('/offer')
#     assert res.status_code == 405

#     # test_delete_offers
#     res = client.delete('/offer')
#     assert res.status_code == 405

#     # test_get_offer_extra_registration
#     res = client.get('/offer/register')
#     assert res.status_code == 405

#     # test_put_offer_extra_registration
#     res = client.put('/offer/register')
#     assert res.status_code == 405

#     # test_delete_offer_extra_registration
#     res = client.delete('/offer/register')
#     assert res.status_code == 405

#     # test_get_request_extra_registration
#     res = client.get('/request/register')
#     assert res.status_code == 405

#     # test_put_request_extra_registration
#     res = client.put('/request/register')
#     assert res.status_code == 405

#     # test_delete_request_extra_registration
#     res = client.delete('/request/register')
#     assert res.status_code == 405