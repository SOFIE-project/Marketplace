Offer Marketplace Architecture
==============================

# Overview

This implementation of the offer marketplace (OM) consists of two main
components:

* **Backend server** that essentially performs all tasks the Ethereum
  smart contract is unable to do. The full extent of this depends a
  bit on the configuration of the setup. This is a REST server with no
  native user-visible web interface.

  The backend server conforms to the SOFIE framework's requirements on
  service discoverablity, descriptiveness and linkage to DLTs.

* **Smart contract** that is integral in offering the
  non-repudiability of the marketplace request-offer-selection
  process. The full extent on what functionality is in the smart
  contract depends on the setup.

  This smart contract conforms to the SOFIE framework's requirements
  on service discoverability, descriptiveness and linkage to non-DLT
  services.

# Structure

The picture below shows the overall structure of this repository.

![](package-class-diagram.png "Package and class diagram")

There are separate package structures for *Solidity* and *Python*
code. The other relevant distinction is between *core code* and *demo
code*.

The demo code contains flower marketplace, a backend with extended
functionality (HTML pages) etc. that extend beyond the base classes
provided by the core code. A "regular" re-use of the code would base
on the core classes, using the demo code only as an example.

# Deployment

While a "real" deployment can be arbitrary complex, for testing
purposes the demo code is deployed. The repository supports (or will
support) two deployment scenarios: local and Kubernetes. The local
deployment basically is for running development version, and the
Kubernetes version contains an automated setup for a running and
useable demonstration environment. Please see the picture below for
major conseptual and practical differences.

![](deployment-diagram.png "Deployment diagram")
