=============
 Public APIs
=============

This document describes the public APIs of the smart contract and the
backend. For details about the *implementation* of these please see
:doc:`smart-contract` and :doc:`backend` instead. See also
:doc:`api-example` for a walk-through example on how to use these APIs
in a few situations

Overview
========

Depending on the configuration of a *specific* offer marketplace
deployment it may be feasible to operate the whole system as:

* Everything is on ledger --- if backend is deployed at all (but not
  necessary), it provides only a read-only version of the ledger data.

* All operations occur on backend --- if smart contract is deployed,
  it is used only as a decentralized and non-repudiable audit trail of
  events, but the actual operations on the ledger are performed by the
  market owner.

* Some mixture of the two --- the backend is used to perform some
  operations, such as pre-approval of offers but the actual offers
  occur on the ledger, as well as all non-repudiation properties are
  provided by the ledger. (Other scenarios such as partial or hidden
  offers and requests also use a backend with an active role.)

For example, if the request data is hidden then the sequence shown
below may occur:

.. seqdiag:: backend-with-hidden-request-data.diag
   :caption: Backend used to query hidden request data, only signed hash is stored on the ledger.

However all of the data is on the ledger, then the sequence can
completely omit the backend server:

.. seqdiag:: ledger-without-hidden-request-data.diag
   :caption: No backend is required when all data is on the ledger.

This sequence may also require prior authentication from the user as
well as separately validate that the user is allowed to see the
details --- consider a case where users can make offers for requests
only that are physically in their area (of grid connectivity).

Use Cases Under Different Deployment Models
===========================================

The core use cases in all situations are:

1. Manage lifecycle of requests (create, close, delete)
2. Create offers for requests
3. Decide which offers are accepted for a request

As implied in the previous section, there are different deployment
models. The core deployment models are:

1. **Ledger as Authority and Data Holder**: All data is included in
   the ledger as-is, and all authority is based on the ledger. The
   backend, if deployed, is onnly a read-only REST interface for this
   data.
2. **Ledger as Authority and Backend as Data Holder**: Ledger still
   operates as the authority of requests and offers, but the backend
   holds the actual data. The data is referred indirectly via signed
   hashes on the ledger, and the actual data is stored and available
   from the backend. This deployment model is useful for both
   situations where the data needs to be hidden, and also when the
   data is too large to be economically feasible to store on a ledger.
3. **Backend as Authority, Ledger as Audit Trail**: The authority is
   delegated fully to the backend, and it uses the ledger only as a
   non-repudiable audit trail of operations. The data may be
   replicated on the ledger, but for example, offers must be sent to
   the system via the backend. (This is the model most close to a
   conventional centralized backend model, and while available via the
   APIs, not really discussed here.)

It is possible to mix some of the authority --- for example, the
ledger can be the authority for requests and offers (manages their
lifecycle), but the decision logic is implemented externally (by the
backend or some other party). Similarly, it is possible that *request
are public* and on the ledger, but *offers* contain hidden data.

The sequences below are applicable for both requests and offers. The
first sequence diagram below shows the situation of a resource
creation for the first deployment model, e.g. with ledger as the full
authority and data holder (this assumes the participant is authorized
to perform the operation):

.. seqdiag:: resource-creation-ledger-authority.diag
   :caption: Creation of a request or an offer where the ledger is the full authority for lifecycle management and data storage. The sequence also shows how a client may fetch the data also from the backend (in case it does not have a ledger interface available), but that the master data comes from the ledger. The data returned in steps 4. and 8. should be identical.

The sequence differs significantly when the backend acts as the data
master, but the ledger is still the lifecycle authority for
resources. This requires a registration of the data as a prior step to
the resource creation:

.. seqdiag:: resource-creation-backend-master.diag
   :caption: Creation of a request or an offer where the ledger is the authority on the resource lifecycle, but the actual data is stored in the backend. For transparency, this requires the validation of the hash signature by both the participant and the smart contract.

Please refer to the sequence diagram in previous section on how the
participant needs to fetch the data from the backend in case it
received only a signed hash for the resource data.

Finally, the third deployment model where all authority resides in the
backend where the ledger is used only as an audit trail would have the
following sequence for resource creation:

.. seqdiag:: resource-creation-backend-authority.diag
   :caption: Creation of a request or an offer where the backend has full authority for the operation and is the data master, even if the data is duplicated on the ledger. Note that in this scenario the resource id number may be assigned by the backend.

So, to reiterate, the diffent sequences of operations for resource
creation are:

1. **Ledger as Authority and Data Holder**:

  1. :sol:interface:`MarketPlace:submitRequest` and :sol:interface:`MarketPlace:submitOffer`
  2. directly followed by appropriate extra data registration method

2. **Ledger as Authority and Backend as Data Holder**:

  1. :http:post:`/request/register/` or :http:post:`/offer/register/`
  2. :sol:interface:`MarketPlace:submitRequest` and :sol:interface:`MarketPlace:submitOffer`
  3. :sol:interface:`RequestSignedHashExtra.submitRequestExtra` or :sol:interface:`OfferSignedHashExtra.submitOfferExtra`

3. **Backend as Authority, Ledger as Audit Trail**:

  1. :http:post:`/request/` or :http:post:`/offer/`


.. note::

   **It is possible that requests and offers have different deployment
   models!** For example, it is possible that the backend is the
   *request* authority, but all offers are made on the *ledger*
   instead. Likewise it is possible that *request data is on ledger*
   but *offer data is hidden but authority is on ledger*. In this
   scenario offer-makers would need to register the offer data on the
   backend followed by a `submitOffer` transaction to the marketplace
   contract.

Requests and Offers
===================

In the offer marketplace, **requests** come first, and **offers** are
made against requests. You can think of a request as a "request for
bids" and an offer as an "offerance of a bid".

Core fields
-----------

The *core* interfaces of the marketplace are agnostic of the actual
resource being traded, and thus the *core* requests and offers have
only a very few fields:

* Request (see :sol:interface:`MarketPlace:getRequest` and
  :http:get:`/request/(int:request_id)`):

  * Unique integer identifier for the request
  * The address of the entity that created the request
  * The deadline for offers to be accepted

* Offer (see :sol:interface:`MarketPlace.getOffer` and
  :http:get:`/offer/(int:offer_id)`):

  * Unique integer identifier for the offer
  * The request against which this offer is being made
  * The address of the entity that created the offer

Note that the request and offer creator fields may not be useful in
all situations. For example, if only the owner of the marketplace can
create requests, then the request creator is really just a
tautology. Similarly, if the submitter of the offer to the smart
contract is acting on behalf of someone else, then the offer creator
really does not tie the offer to the actual entity making the
offer. Whether these fields are useful depends very much on the
semantics of the marketplace.

Extra data
----------

Everything else is stored as "extra data". This does actually include
all "useful" data that creates the actual semantics of a specific
marketplace. The interface to submit and access behave differently for
REST API and Smart Contract API:

* For REST, the use of JSON allows dynamic inclusion of the extra data
  easily, so the extra data is just a mapping in request and offer
  data called ``extra``.

* In contrast, the Ethereum smart contract needs to be frugal of
  resource use (JSON parsing is a killer for gas cost) as well as due
  to the cumbersomeness of Ethereum ABI specification (and Solidity)
  and the "extra" interfaces are separated from core request and offer
  APIs. See :sol:interface:`MarketPlace.submitOffer` and
  :sol:interface:`ArrayExtraData.submitOfferExtra` as examples.

The semantic meaning of this "extra data" is always tied to a specific
type of marketplace. If the marketplaces operate on the same data
structures, it is possible they also use the same type identifier for
the market type (:sol:interface:`MarketPlace.getType`).

Backend REST API
================

.. note::

   The general backend API encompasses all of the use cases --- data
   on ledger, signed hashes on ledger, master data in backend with
   only audit records on ledger. It is important to understand that in
   different uses cases some of the API is not used at all. For
   example, if all data is on ledger, then request creation occurs via
   the Smart Contract API, and not via the backend API. If only hashed
   data is on the ledger, then the register interfaces for request and
   offer data are used on the backend. If the backend is the full
   authority on all data, then it is used for request and offer
   creation.

The backend REST API is defined in terms of CRUD resources for
requests and offers plus some related actions. This API does **not**
tackle things such as authentication and authorization. It is assumed
that the requestor knows how to proceed any required authorization
information in the request, and knows how to handle ``401`` and
``403`` return codes.

All responses of ``200 OK`` must have ``Content-Type:
application/json`` and return a JSON response. Error responses should
also have JSON response with the JSON fields ``status`` equaling the
HTTP status code and ``error`` with an error name, optionally
including also a ``message`` field with a longer error
description. For example:

.. sourcecode:: http

   HTTP/1.1 403 Forbidden
   Content-Type: application/json

   {
     "status": 403,
     "error": "Forbidden",
     "message": "You are not authorized to access this resource"
   }

General information
-------------------

.. http:get:: /info

   General marketplace information. Although this interface **can**
   return ``401`` and ``403``, it is more advisable to return
   information here (even if redacted) and then require authentication
   for more detailed requests.

   .. note:: This needs also to include the public key that can be
             used to validate signed hashes if backend holds the
             master data (with ledger having only signed hashes).

   **Example response**:

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "type": "eu.sofie-iot.offer_marketplace.flower",
	"contract": {
	  "address": "0x6457AC5F9F8676B9223dE791571C5E8f86F1db13",
	  "network": 4
	}
      }

   :>json string type: Type identifier of the marketplace
   :>json object contract: Information about the smart contract,
			   omitted if none exist
   :>json string contract.address: EIP-55 checksummed address of the contract
   :>json int contract.network: Network id for the network the
				contract is deployed in
   :statuscode 200: Success
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

Requests
--------

.. http:get:: /request/

   Returns the list of requests. This may include open, closed or both
   open and closed requests depending on the query parameters.

   **Example response with default query parameters**:

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "requests": [
	  {
	    "id": 1,
	    "deadline": "2031-01-09T000000Z",
	    "state": "open",
	    "decided": null,
	    "decision": null,
	    "offers": [{"id": 10}],
	    "extra": {}
	  },
	  {
	    "id": 2,
	    "deadline": "2018-08-19T010530Z",
	    "state": "decided",
	    "offers": [{"id": 7}, {"id": 12}],
	    "extra": {},
	    "decided": "2018-08-20T000000Z",
	    "decision": [{"id": 7}]
	  }
	]
      }

   (extra fields are left empty in this example)

   **Example response with query parameters** (``?ids_only=1&state=decided``):

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "requests": [{"id": 2}]
      }

   :query state: comma-separated list of ``open``, ``closed`` and
                 ``decided`` (default is ``open``), or ``all``
   :query ids_only: either 0 or 1, if 1, then all details of requests
                    are omitted and only the request id is included
                    (default is 0)
   :>json array requests: array of request objects (see
                          :http:get:`/request/(int:request_id)` for
                          details on the request object structure)
   :statuscode 200: Success
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

.. http:get:: /request/(int:request_id)

   Returns the details of a specific request.

   **Example response** (this uses extra data format from the flower
    marketplace example):

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "id": 1124,
	"state": "open",
	"decision": null,
	"deadline": "2019-01-06T12:05:00Z",
	"extra": {
	  "flower_type": "tulip",
	  "quantity": 500
	},
	"offers": [{"id": 9924}, {"id": 10650}]
      }

   **Example response for decided request**

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "id": 1124,
	"state": "decided",
	"decision": [{"id": 125511}, {"id": 120019}],
	"deadline": "2019-01-06T12:05:00Z",
	"decided": "2019-01-06T12:10:00Z",
	"extra": {
	  "flower_type": "tulip",
	  "quantity": 500
	},
	"offers": [{"id": 9924}, {"id": 10650}, {"id": 125511}, {"id": 120019}]
      }

   :query ids_only: either 0 or 1, if 1, then all details of offers
                    for the request are omitted and only the request
                    id is included (default is 1 -- note that this is
                    **reverse** from the same field in
                    :http:get:`/request/`)
   :>json int id: The unique request identifier
   :>json string state: One of ``open``, ``closed`` or ``decided``,
                        represents the state of the request
   :>json array|null decision: The decision for the request. This is
                               meaningful only if state is
                               ``decided``, otherwise it should be
                               ``null``. For decided requests this is
                               the list of offers that were selected.
   :>json string|null decided: The decision time --- note that in some
			       cases this is approximate value due to
			       the inaccuracies related to block
			       timestamps.
   :>json string decided: Timestamp of the decision for ``decided``
			  requests, ``null`` otherwise. The timestamp
			  is ISO 8601 formatted.
   :statuscode 200: Success
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden
   :statuscode 404: Not found

Offers
------

.. http:get:: /offer/
   Returns the list of offers. This may include open, closed or both
   open and closed offers depending on the query parameters.

   **Example response with default query parameters**:
   {
      "offers": [
         {
            "id": 1,
            "request_id": 3,
            "author": "0xDbf6c3491Fb057D3a0a11B8eD7Bf3d0b61B451F7",
            "extra": [
                91
            ],
            "state": "open"
         },
         {
            "id": 2,
            "request_id": 6,
            "author": "0xc2A85077d48931aeb0D47F86A071fA15Ae05E704",
            "extra": [
                78
            ],
            "state": "open"
         },
   }

   :<json object offers: Array of offers, see
			 :http:get:`/offer/(int:offer_id)` for
			 description of the individual elements in the array.

   :statuscode 200: Success
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

.. http:get:: /offer/(int:offer_id)
   Returns the details of a specific offer.

   **Example response** (this uses extra data format from the flower
    marketplace example):

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json
      
      {
         "id": 6,
         "request_id": 18,
         "author": "0xf21a8275C4718Ffb26f3D32593dA6523407FBFc4",
         "extra": [
            99
         ],
         "state": "open"
      }

   :statuscode 200: Success
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

.. http:post:: /offer/

   :<json int request_id: Request id to put the offer against
   :<json object extra: Extra parameters

   **Example response**:

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "offer_id": 2
      }   

   :statuscode 200: Success
   :statuscode 202: Accepted
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden
   :statuscode 404: Request not found

.. http:put:: /offer/(int:offer_id)
   No implementation for the moment

   :statuscode 200: Success
   :statuscode 202: Accepted
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

.. http:delete:: /offer/(int:offer_id)
   No implementation for the moment

   :statuscode 202: Accepted
   :statuscode 204: Deleted
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden
   :statuscode 409: Conflict

.. http:post:: /offer/register/

   :<json int request_id: Request id to put the offer against
   :<json object extra: Extra parameters

   **Example response**:

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "offer_id": 2
      }   

   :statuscode 200: Success
   :statuscode 202: Accepted
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden
   :statuscode 404: Request not found



Management Operations
---------------------

There are several operations that are typically restricted to owners
or managers of the marketplace. These include request creation,
decision, and removal e.g. the request lifecycle.

.. http:post:: /request/

   Create a new request. This method is often restricted to only
   authorized users. This often also causes a transaction to be
   initiated on the blockchain to actually submit a request.

   This method may return ``202 Accepted`` if the request creation has
   started, but may run for a long time (for example, waiting for
   smart contract transaction to complete). If ``202`` is returned,
   the result must contain a field ``status_url`` that can be polled
   --- that URL should either return ``202`` if the operation is still
   pending, or the actual result of the original request.

   **Example request**:

   .. sourcecode:: http

      POST /request/ HTTP/1.1
      Content-Type: application/json
      Authorization: ...

      {
      }

   **(fields are missing from request)**

   **Example response**:

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "id": 22451
      }

   **(fields are missing from response)**


   **Example sequence with 202 Accepted response**:

   .. sourcecode:: http

      POST /request/ HTTP/1.1
      Content-Type: application/json
      Authorization: ...

      {
      }

   **(fields are missing from request)**

   .. sourcecode:: http

      HTTP/1.1 202 Accepted
      Content-Type: application/json

      {
        "status_url": "/pending_request/?tx=0x838f8888a4323...ffae"
      }

   .. sourcecode:: http

      GET /pending_request/?tx=0x838f8888a4323...ffae HTTP/1.1

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "id": 22451
      }

   **(fields are missing from response)**

   :<json string deadline: Deadline for the request (ISO 8601 format)
   :<json object extra: Extra request parameters
   :>json int id: Request identifier
   :>json string deadline: The deadline parameter, potentially
                           adjusted by the server (due to resolution
                           etc.)
   :>json object extra: Extra request parameters, as interpreted and
                        stored by the system
   :statuscode 200: Success
   :statuscode 202: Accepted
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden


.. http:put:: /request/(int:request_id)

   Update the state of a request. Depending on the configuration there
   are only a few valid operations:

   * Change state from ``open`` to ``closed``
   * Change state from ``closed`` to ``decided``, optionally supplied with
     ``decision`` values
   * Change state from ``open`` to ``decided``, with or withou
     ``decision`` values

   If the decision is performed by the smart contract, then the
   backend initiates the decision on the smart contract, and the
   backend will track the state of the request (in the ``GET``
   operation) with the state of the ledger.

   If in contrast the decision is made at the backend, then two paths
   are open: on ``open`` to ``closed`` transition the backend may know
   how to perform the decision, and does it. Alternatively the
   decision is made by some other process, and in that case it must be
   explicitly specified via ``closed`` to ``decided`` transition (or
   directly from open to decided).

   Note that *what transitions are valid* is defined by the
   marketplace itself. Also, it is possible for a ``PUT`` to return a
   ``202 Accepted`` just as with :http:post:`/request/` with the same
   semantics.

   The return value for ``200 OK`` is the updated request state, for
   ``202 Accepted`` the URL to check for updates.

   **Example request**

   .. sourcecode:: http

      PUT /request/2 HTTP/1.1
      Content-Type: application/json
      Authorization: ...

      {
        "state": "decided",
	"decision": [{"id": 7}]
      }

   :<json string state: One of ``closed`` and ``decided``
   :<json array decided: Array of offer ids that were accepted for the
                         request
   :statuscode 200: Success
   :statuscode 202: Accepted
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

.. http:delete:: /request/(int:request_id)

   Delete a request. The request must be in either closed or decided
   state. Also, some environments or smart contracts may enforce a
   minimum time from close or decision until a request can be removed
   in which case ``409`` is returned. This operation may return ``202
   Accepted`` with the same semantics as with :http:post:`/request/`.

   :statuscode 202: Accepted
   :statuscode 204: Deleted
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden
   :statuscode 409: Conflict

.. http:post:: /request/register/

   :<json int request_id: Request id to put the extra data
   :<json object extra: Extra request parameters

   :statuscode 200: OK
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

   
Callbacks for Marketplace Events
--------------------------------

It is possible to register callbacks that will be called after the Marketplace 
smart contract emits some event, for example `RequestAdded`.

.. http:get:: /subscription/events/

   Returns a list of available events for subscription. For example:
    
   .. sourcecode:: http
    
      HTTP/1.1 200 OK
      Content-Type: application/json
      
      {
        "events": [
            "RequestAdded", 
            "RequestExtraAdded", 
            "OfferAdded", 
            "OfferExtraAdded", 
            "FunctionStatus", 
            "OwnershipTransferred"
        ]
      }

   :>json object events: Array of available event names as strings, for which a 
        subscription can be requested.

   :statuscode 200: Success
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

   
.. http:post:: /subscription/

   Subscribes to the specific event.
   
   **Example request**:

   .. sourcecode:: http

      POST /subscription/ HTTP/1.1
      Content-Type: application/json

      {
        "event": "RequestAdded",
        "url": "https://mydomain.com/marketplace/callback/"
      }

   **Example response**:

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Content-Type: application/json

      {
        "id": "c073a476-efd6-4dab-a93d-275d74526538"
      }
   
   :<json string event: Name of the event to subscribe to
   :<json string url: Callback URL
   :>json string id: Subscription identifier in UUID version 4 format, 
        which is used to view, update, or delete the subscription.

   :statuscode 200: Success
   :statuscode 400: Invalid request
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

   
.. http:get:: /subscription/(string:id)

   Returns the event name and callback URL of the existing subscription.

   :>json string event: Name of the event
   :>json string url: Callback URL
   
   :statuscode 200: Success
   :statuscode 400: Invalid request
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

   
.. http:put:: /subscription/(string:id)

   Updates the existing subscription, the request must provide either 
   a new event name or new callback URL.
   
      **Example request**:

   .. sourcecode:: http

      PUT /subscription/c073a476-efd6-4dab-a93d-275d74526538 HTTP/1.1
      Content-Type: application/json

      {
        "url": "https://anotherdomain.com/marketplace/callback/"
      }

   :<json string event: Optional new name of the event to subscribe to
   :<json string url: Optional new callback URL
      
   :statuscode 200: Success
   :statuscode 400: Invalid request
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden

   
.. http:delete:: /subscription/(string:id)

   Deletes the existing subscription.

   :statuscode 204: Deleted
   :statuscode 400: Invalid request
   :statuscode 401: Authentication required
   :statuscode 403: Forbidden



Marketplace Contract API
========================

The main marketplace interface is defined as
:sol:interface:`MarketPlace` and consists of operations that are
needed by the *submitter of offers*. There are also operations that
are related to the creation of requests, but these are in the
:sol:interface:`MarketPlaceRequest` interface. The rationaly for
separation of these two interfaces is that the underlying assumption
of the marketplace is that it is highly assymmetric --- there is
usually only one entity submitting requests, whereas many operating on
the offers. Thus the interface that the offer-maker faces is designed
to include **only** operations that are required to operate on offers.

Note that **all deployed marketplaces must implement ERC165** to
support interface identification (this becomes especially important
with extra data methods).

MarketPlace Solidity Interface
------------------------------

.. autosolinterface:: MarketPlace
   :members:

Hidden Request and Offer Data
=============================

  See :http:post:`/request/register/` and
  :http:post:`/offer/register/` for the interfaces on how hidden
  request and offer data is submitted to the backend. Rest of this
  section described in more detail *how* the actual return value is
  generated for these requests.

If all or a portion of request or offer data is "hidden", e.g. not
part of the smart contract request and offer data, it may be needed to
employ signed hashes (for non-repudiation) to vouch for some of the
data. To make this work, two additional elements and steps are
necessary:

1. Signing key that the backend uses to sign hashes
2. Generating hashes from the request and offer data

We are going to skip the problem with the signing key for now and just
assume there is a way to sign a hash in a way that all parties in the
offer marketplace can verify to have been signed by the backend (or
some other trusted entity).

For the second problem, let's just say there is a way to consistently
hash the following fields in request and offer:

  * ``deadline``
  * ``extra``
  * ``request_id`` for offers

The hash should also include a timestamp value ``generated``, a
ISO8601-formatted timestamp when the hash was calculated. This field
needs to be included in the final data that is sent, e.g. the final
issuance of the signed and hashed data is::

    (generated, hash, signature)

The generation timestamp is included to allow others to evaluate the
freshness of the signed hash.

    Yes, both the signature generation (e.g. which cryptographic
    mechanisms to use) and the problem of consistent serialization are
    completely overlooked currently.

Mapping from Terni ``rest.py`` to Backend REST API
==================================================

**Notice: This section will be eventually removed, it is included in
the document for discussion purposes.**

Interface Mapping
-----------------

The existing ``rest.py`` implementation from the Terni pilot currently
has these API endpoints::

  /addRequest/<quantity>/<zone>/<requestDate>/<deadline>/<startDate>/<endDate>/<maxPrice>/<user>/<token>
  /list
  /offer/<id>/<price>/<user>/<token>
  /showRequest/<id>
  /decide/<id>/<user>/<token>
  /showRequestWon/<which>/<author>
  /pay/<id>/<user>/<token>
  /listAll
  /tokenBalance/<address>
  /myAddress

Looking at the implementation these seem to map like this:

* ``/addRequest`` → :http:post:`/request/` (with ``extra`` parameters)
* ``/list`` → :http:get:`/request/`
* ``/offer`` → :http:post:`/offer/` (with ``extra`` parameters)
* ``/showRequest`` → :http:get:`/request/(int:request_id)`
* ``/decide`` → :http:put:`/request/(int:request_id)` (with ``state``
  change to ``decided``)
* ``/showRequestWon`` → no direct match, this seems to look for
  requests won by the requestor
* ``/listAll`` → :http:get:`/request/` with query ``?state=all``
* ``/myAddress`` → :http:get:`/info`

The following ones are related to the ERC-20 and post-decision
processes which have no direct meaning in the offer marketplace core
itself. These would be marketplace-specific extensions to the core
backend APIs.

* ``/pay``
* ``/tokenBalance``

Authentication and Authorization
--------------------------------

Regarding **authentication**, the mechanism used in ``rest.py`` is to
pass a ``<token>`` in request parameters. The canonical RESTful way is
to use the ``Authorization`` field with the ``Bearer`` type (see
https://tools.ietf.org/html/rfc6750). The backend API does not
directly define how a user is authenticated and authorized, but a
reasonable method would be:

* If needed, add ``/login`` endpoint (marketplace-specific extension)
  that is used to perform a login process (using whatever is
  applicable for the marketplace, such as OAuth2) -- OTOH, ``rest.py``
  does not have a mechanism to perform authentication, it assumes the
  existence of a token and a verification service somewhere else, thus
  if the same method is followed then no such login endpoint is needed
  for the Terni case.

* The backend **implementation** would have a pluggable
  authentication/authorization mechanism, e.g. it would be possible to
  define a Terni-specific authorization class like this (not final
  interface)::

    class TerniAuthorization(sofie_offer_marketplace.backend.Authorization):
      def authorize(self, request):
        if 'Authorize' not in request.headers:
	  abort(401)

	fields = request.headers['Authorize'].split()

	if len(fields) != 2 or fields[0] != 'Bearer':
	  abort(401)

	token = fields[1]

	if not check_with_auth_backend(token):
	  abort(403)

	return
