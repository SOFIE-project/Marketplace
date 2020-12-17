# Example Use Cases of Offer Marketplace

This document describes several application use cases that utilise the SOFIE Marketplace interfaces.

## Flower Marketplace

The [flower marketplace](../solidity/contracts/FlowerMarketPlace.sol) is built for selling flowers in an open bidding: the participants can compete in the market to bid for the flowers.

By implementing the core Marketplace interfaces and other related abstract classes, the smart contract works in the following steps. First, it allows the owner or manager to submit requests for the commodity. Afterwards, other parties can compete for the request by submitting offers to the contract while the request remains open. Finally, the requestor can close the request he or she made, and the offer with the best price wins (usually the highest price). 

This serves as a simple example of how to tailor the Marketplace interfaces for the application. Application developers can use this example as the base to design their own logic for the offer marketplace.

## Beach Chair Marketplace

The [beach chair marketplace](../solidity/contracts/BeachChairMarketPlace.sol) is similar to the flower marketplace above. The main difference in this example is that an integrity check on the offers is added when a request is to be decided, so that there is no invalid or redundant offer identifiers among the accepted offer IDs. 

This serves as a simple exampe for application developers as well. Note that both the flower marketplace and the beach chair marketplace adopts the simple bidding pricing model, meaning that the offer with the best price will win the request.

## House Renovation Marketplace

This marketplace [smart contract](../solidity/contracts/HouseRenovationMarketPlace.sol) is based on a hypothetical story of house renovation. Requests are made for house renovation, where a price limit (the high margin) and a price target (ideal low margin) is set in the request.

The companies or agents compete by offering bids (lower bid is better from the requestor point of view). And the first bid to reach the target price will win bidding by default (the requestor has a possibility to close the request without approving any offers). This logic is achieved inside the closing process of a request in this example. Application developers have the flexibility to end the request once an offer reaches the price limit, based on the application scenarios.

This use case is an example for the fixed price model.

## Energy Marketplace

The smart contracts in [/solidity/vendors/ENG](../solidity/vendors/ENG) directory belong to the the real industry use cases from [Engineering](https://engineering.it) in the [Decentralised Energy Flexibility Marketplace pilot](https://media.voog.com/0000/0042/0957/files/sofie-onepager-energy-exchange_final.pdf). 

The energy marketplace smart contracts are used for a real-world application scenario of trading electricity flexibility requests, in which case the metadata of requests and offers are more complicated than in the previous examples. Despite some refactoring of the dependent smart contracts, the general idea and interfaces of the marketplace remain the same.

The integration of payment for accepted trades is introduced by this example, specifically in this case an ERC20 token is used for the payment. Application developers can integrate payments to the Marketplace by following the approach shown in this example.
