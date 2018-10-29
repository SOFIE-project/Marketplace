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





TBD.
