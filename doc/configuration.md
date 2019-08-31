Configuration
=============

*This file seems a bit out of place, maybe to be removed later?*

## Python

The :class:`sofie_offer_marketplace.Marketplace` class represents an
instantiation of a single marketplace. It will receive as input
parameters **minimally** the following information:

* Smart contract address and web3 instance / or web3 API instance pointing to it (TBD)
* Address to be used for interacting with the contract (or can this be
  implicit from previous?)
* Flag specifying whether this is manager or offerer role the
  marketplace class instance is being used for (also for owner etc.)
  (these could be checked from the contract view functions, actually)
* Model classes for requests and offers of the marketplace (used for
  marshalling and unmarshalling data)
