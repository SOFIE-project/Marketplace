Smart Contract
==============

This document describes some of the things required of the smart
contract (see [`solidity`](/solidity/) directory).

# General Requirements

The smart contract needs to support:

* [ERC-165](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md)

* Follow general "best practices" (see [ConsenSys
  pages](https://consensys.github.io/smart-contract-best-practices/)
  for example)
* Cleanly re-usable, e.g. extendable contract that has method stubs
  for operations that cannot be part of the generic interface

# Specification

> **NOTE**: This specification is guaranteed to change over time while
> this BP is co-developed with RP and SOFIE pilots.

The smart contract needs to be constructed of multiple pieces,
e.g. mixins and base classes. The mixins implement different
categories of the functionality while the base class handles other
configurable aspects.

The tentative offer marketplace interface is like this:

```
interface OfferMarketplace {
	function getMarketInformation() returns (... ??? ...) public;
	function getOpenRequestIdentifiers() returns (uint256[]) public;
	function getRequest(uint256 requestIdentifier) returns (... ??? ...) public;
	function submitOffer(uint256 requestIdentifier, uint256 participant, uint256 offerId, ...) returns (bool) public;
	function isRequestDefined(uint2256 requestIdentifier) returns (bool);
	function isRequestDecided(uint256 requestIdentifier) returns (bool);
	function getRequestDecision(uint256 requestIdentifier) returns (uint256[], uint256[]) public;
}
```

The actual contract constructor of the base contract needs to be
something like this:

```
contract OfferMarketpleBaseContract is OfferMarketplace {
	function A(string _infoUrl, ...) internal {
		...
	}
}
```

This is an abstract contract and will use several internal (private)
methods to do some of the aspects that need configurability. There
are different variants of the system that need to be defined through
mix-ins to allow contract compile-time configurability:

* Are offers accepted only if a valid signature is provided? In this
  case an `interface` that allows for accepted public key management,
  and a mix-in implementation of that interface. Also, a method that
  uses this implementation to validate the request is needed.

* Are offers accepted only from specific addresses? The same applies
  as above. Note that it is possible that **both** mechanisms are used
  simultanously, e.g. offers are accepted only from specific addresses
  **and** they need to be signed, and the key to validate the
  signature must be paired with the address. (Note: this will also
  mean that the signature format needs to be specified in a manner
  that can be verified in Ethereum.)

* Are offers submitted first externally (to the backend), and only
  after that to the smart contract? If so, the contract needs to
  validate the signature of the offer (generated at the backend)
  against the backend's public key.

* Can offers be cancelled? Again, interface and implementation.

And so on. There are a ton of variability in these situations.

In general the **final** contract to be deployed is constructed from
base classes and mixins in somewhat this style:

```
contract FlowerMarketplace is OfferMarketplaceBaseContract, ApprovedAddressMixin, OfferCancellationMixin {
	function FlowerMarketplace(...) public {
		// constructor
	}

	function isOfferValid(address sender, ...) private returns (bool) {
		// isAddressApproved is internal method from ApprovedAddressMixin
		if (!_isAddressApproved(sender))
			return false;

		// here we could check some other things too
		return true;
	}

	function addApprovedAddress(address addr) public onlyOwner {
		// this is provided by ApprovedAddressMixin
		_addApprovedAddress(addr);
	}

	function removeApprovedAddress(addres addr) public onlyOwner {
		_removeApprovedAddress(addr);
	}

	// and so on for cancellable and others
}
```

# Open issues

* How and in what format market information is returned
  (e.g. `getMarketInformation`)
* What information is returned in `getRequest`? Do we need to split
  out generic (see BP specification) and market-specific information?
  Or should all different information items be through different
  getters (e.g. `getRequestOpenInterval`,
  `getRequestDecisionInterval`, `getRequest...`?)
* Similarly, how do we handle offer format variance?

These probably are best approached by constructing a few different
marketplace implementations and seeing how reusability can be achieved
between them:

* Terni pilot case
* Selling flowers (see BP specification for description of this case)
* Car rental (-"-)
