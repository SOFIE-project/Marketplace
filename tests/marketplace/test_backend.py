import pytest


def test_get_request(client):
    result = client.get('/request/1')
    assert result.status_code == 501


def test_put_request(client):
    result = client.put('/request/1')
    assert result.status_code == 501


def test_delete_request(client):
    result = client.delete('/request/1')
    assert result.status_code == 501


def test_get_offer(client):
    result = client.get('/offer/1')
    assert result.status_code == 501


def test_put_offer(client):
    result = client.put('/offer/1')
    assert result.status_code == 501


def test_delete_offer(client):
    result = client.delete('/offer/1')
    assert result.status_code == 501


def test_get_information(client):
    result = client.get('/info')
    assert result.status_code == 501


def test_get_requests(client):
    result = client.get('/request')
    assert result.status_code == 501


def test_post_requests(client):
    result = client.post('/request')
    assert result.status_code == 501


def test_get_offers(client):
    result = client.get('/offer')
    assert result.status_code == 501


def test_post_offers(client):
    result = client.post('/offer')
    assert result.status_code == 501


def test_post_offer_extra_registration(client):
    result = client.post('/offer/register')
    assert result.status_code == 501


def test_post_request_extra_registration(client):
    result = client.post('/request/register')
    assert result.status_code == 501


def test_offer_invalid_methods(client):
    # test_post_request
    result = client.post('/request/1')
    assert result.status_code == 405

    # test_post_offer
    result = client.post('/offer/1')
    assert result.status_code == 405

    # test_post_information
    result = client.post('/info')
    assert result.status_code == 405

    # test_put_information
    result = client.put('/info')
    assert result.status_code == 405

    # test_delete_information
    result = client.delete('/info')
    assert result.status_code == 405

    # test_put_requests
    result = client.put('/request')
    assert result.status_code == 405

    # test_delete_requests
    result = client.delete('/request')
    assert result.status_code == 405

    # test_put_offers
    result = client.put('/offer')
    assert result.status_code == 405

    # test_delete_offers
    result = client.delete('/offer')
    assert result.status_code == 405

    # test_get_offer_extra_registration
    result = client.get('/offer/register')
    assert result.status_code == 405

    # test_put_offer_extra_registration
    result = client.put('/offer/register')
    assert result.status_code == 405

    # test_delete_offer_extra_registration
    result = client.delete('/offer/register')
    assert result.status_code == 405

    # test_get_request_extra_registration
    result = client.get('/request/register')
    assert result.status_code == 405

    # test_put_request_extra_registration
    result = client.put('/request/register')
    assert result.status_code == 405

    # test_delete_request_extra_registration
    result = client.delete('/request/register')
    assert result.status_code == 405
