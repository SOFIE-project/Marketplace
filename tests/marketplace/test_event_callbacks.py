import json
import time
import redis


r = redis.Redis(host='localhost', port=6379, db=0)

r.set('cb_response', '') # erase any existing data
assert r.get('cb_response') == b''

# 1. Retrieve event types available
def test_event_types(client, web3contract):
    # GET /subscriptions/events
    res = client.get('/subscription/events')
    assert res.status_code == 200

    res_obj = res.get_json()
    assert 'events' in res_obj
    events = res_obj['events']
    # based on the flower marketplace
    assert "RequestDecided" in events
    assert "RequestClosed" in events
    assert "RequestAdded" in events
    assert "RequestExtraAdded" in events
    assert "OfferAdded" in events
    assert "OfferExtraAdded" in events
    assert "FunctionStatus" in events
    assert "OwnershipTransferred" in events


# 2. Subscribe to an event
def test_subscribe_to_event(client, web3contract):
    # POST /subscription
    res = client.post('/subscription', json={
        'event': "RequestAdded",
        'url': "https://jsonplaceholder.typicode.com/posts"
    })

    assert res.status_code == 200
    
    res_obj = res.get_json()
    assert 'id' in  res_obj
    subscription_id = res_obj['id']

    event_subscriptions = json.loads(r.get('event_subscriptions').decode('utf-8'))

    assert subscription_id in event_subscriptions["RequestAdded"]

    # GET /subscription/:id
    res = client.get(f'/subscription/{subscription_id}')
    assert res.status_code == 200

    res_obj = res.get_json()
    assert 'event' in res_obj
    assert 'url' in res_obj


# 3. Ledger event triggers callback
def test_event_trigger_callback(client, web3contract):
    # add a request to trigger event "RequestAdded"
    # POST /request
    res = client.post('/request', json={
        "deadline": 2000000004
    })
    assert res.status_code == 200
    res_obj = res.get_json()
    request_id = res_obj["id"]

    # Logging information from the celery task can be observed
    # for invoking the callback of each subscriber

    time.sleep(20) # mimic the processing of callback

    cb_reponse_raw = r.get('cb_response')
    print(cb_reponse_raw)
    cb_response = json.loads(cb_reponse_raw.decode('utf-8'))
    print(cb_response)
    assert 'data' in cb_response


# 4. Update & remove subscriptions
def test_manipulate_subscriptions(client, web3contract):
    # POST /subscription
    res = client.post('/subscription', json={
        'event': "RequestExtraAdded",
        'url': "https://jsonplaceholder.typicode.com/posts"
    })

    assert res.status_code == 200
    
    res_obj = res.get_json()
    assert 'id' in  res_obj
    subscription_id = res_obj['id']

    # GET /subscription/:id
    res = client.get(f'/subscription/{subscription_id}')
    assert res.status_code == 200

    res_obj = res.get_json()
    assert 'event' in res_obj
    assert res_obj['event'] == "RequestExtraAdded"
    assert 'url' in res_obj

    # PUT /subscription/id
    res = client.put(f'/subscription/{subscription_id}', json={
        'event': "OfferExtraAdded"
    })

    assert res.status_code == 200

    # GET /subscription/:id
    res = client.get(f'/subscription/{subscription_id}')
    assert res.status_code == 200

    res_obj = res.get_json()
    assert 'event' in res_obj
    assert res_obj['event'] == "OfferExtraAdded"
    assert 'url' in res_obj

    # DELETE /subscription/id
    res = client.delete(f'/subscription/{subscription_id}')

    assert res.status_code == 204

    # GET /subscription/:id
    res = client.get(f'/subscription/{subscription_id}')
    assert res.status_code == 400
    