# Marketplace

## Table of Contents
- [Description](#Description)
    - [Architechture Overview](#Architecture-Overview)
    - [Relation with SOFIE](#Relation-with-SOFIE)
    - [Key Technologies](#Key-Technologies)
- [Usage](#Usage)
    - [Prerequisites](#Prerequisites)
    - [Installation](#Installation)
    - [Execution](#Execution)
		- [Deployment](#Deployment)
    - [Re-using the template](#Re-using-the-template)
    - [Docker Images](#Docker-Images)
- [Testing](#Testing)
    - [Prerequisites](#Prerequisites)
    - [Running the Tests](#Running-the-Tests)
    - [Evaluating Results](Evaluating-Results)
- [Generating Documentation](#Generating-Documentation)
- [Open Issues](#Open-Issues)
- [Future Work](#Future-Work)
- [Contact Info](#Contact-Info)
- [License](#License)

## Description

The SOFIE Marketplace component provides a generic model of request-offer (or
proposal-bid) batch transaction model. It can used to implement autions using different pricing models.

Examples of how the Marketplace can be used include
- [flower marketplace](doc/examples.md/#Flower-Marketplace) and the [beach chair marketplace](doc/examples.md/#Beach-Chair-Marketplace), which are auctions, where the highest bid (or lowest depending on the auction)  wins
- [house renovation marketplace](doc/examples.md/#House-Renovation-Marketplace), which is a fixed price auction

### Architecture Overview

The goal of the SOFIE Marketplace component is to enable the trade of
different types of assets in an automated, decentralised, and flexible
way. The actors (buyers and sellers) are able to carry out trades by
placing bids and offers using the marketplace component, which
utilises *Ethereum smart contracts*.

Figure 1 shows an overview of the Marketplace component and its interfaces. 
The Marketplace component offers two interfaces: *Request Maker* for sellers 
to create, manage, and conclude auctions, and *Offer Maker* for buyers to 
participate and bid in auctions.

![MarketplaceInterfaces](doc/images/MarketplaceInterfaces.png)

Figure 1: Marketplace component's interfaces

Figure 2 shows an internal structure of the marketplace component. 
*MarketplaceModule* includes functionality to communicate with Marketplace smart 
contracts (which are shown in dotted line). *MarketplaceInterface* smart contract 
includes *Offer Maker* and *Request Maker* interfaces. *MarketplaceBase* includes all 
of base functionalities for the marketplace component, while *EthereumStandards*
includes the standard Ethereum tokens like
[ERC20](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md).


![MarketplaceClasses](doc/images/MarketplaceClasses.png)
Figure 2: Internal structure of the Marketplace component

The component's technical design and architecture documentation can be
found in the [doc](/doc/) directory.

#### Pricing models

On the application logic level, the following two types of pricing models have been implemented with concrete smart contract examples:

- **Simple bidding**: In this model, as long as a request remains open, new offers can be added. Finally, when the auction closes, the offer with the highest (or lowes depending on the aution type) price is selected. The example use cases of the [flower marketplace](doc/examples.md/#Flower-Marketplace) and the [beach chair marketplace](doc/examples.md/#Beach-Chair-Marketplace) show the details of mechanism of this type of pricing model.

- **Fixed price**: The fixed price bidding model allows the request maker to set a threshold value, and the first offer that reaches wins the request. The [house renovation marketplace](doc/examples.md/#House-Renovation-Marketplace) is an example of this type of price model.

### Relation with SOFIE

This repository contains a **template** that implements the *Offer Marketplace* business platform as described as part of the SOFIE project's [Business Platforms document](https://media.voog.com/0000/0042/0957/files/SOFIE_D3.2-Business_Platform_Lab_Prototype_Release.pdf).

### Key Technologies

This component uses [*Flask*](https://palletsprojects.com/p/flask/) for back-end web services 
and *Ethereum Smart Contracts* written in [*Solidity*](https://solidity.readthedocs.io/) for interacting with [*Ethereum Blockchain*](https://ethereum.org/). Also, *offer-marketplace-cli* uses [*web3.py*](https://github.com/ethereum/web3.py) library in order to interact with the smart contracts.


***

## Usage

The SOFIE Marketplace component is composed of following parts:
* Solidity smart contracts located in `solidity/contracts` and `solidity/vendors/ENG` directories
* Flask backend for interacting with smart contracts (currently under development and not finished yet) located in `src/sofie_offer_marketplace/backend`
* Command line tool for interacting with Marketplace located in `sofie_offer_marketplace_cli`
* Python Marketplace classes used by the backend and command line tool located in `src/sofie_offer_marketplace`


### Prerequisites

You can install dependencies for the Flask backend and Command line tool by running the following commands (requires Python setuptools package, which can be installed by running: `pip install setuptools`):

	$ python3 setup.py build
	$ python3 setup.py install
	
You can skip the steps above when interacting with smart contracts directly.

### Installation

#### Install Smart Contracts using NPM

Users who need only the essential smart contracts related to Marketplace interfaces and their example implementations have the option to use the separate [SOFIE Marketplace npm module](https://www.npmjs.com/package/sofie-offer-marketplace) without the need to include this whole repository.

```bash
npm install sofie-offer-marketplace
```

This command installs the module with all the essential smart contracts of interfaces and template implementations. These can then be extended for a custom application logic.

### Execution

#### CLI 
For trying out the marketplace tool `offer-marketplace-cli`, following steps 
should be performed. First, set up truffle and a local Ethereum node 
(Ganache CLI, for example):

	$ cd solidity/
	$ npm install
	$ npm install -g ganache-cli
	$ ganache-cli -p 7545
	$ npx truffle migrate --reset --network ganache
	$ cd ..
	
Then:

	$ export WEB3_PROVIDER_URI=http://localhost:7545
	$ export MARKETPLACE_ACCOUNT=account-id-from-ganache-console
	$ export MARKETPLACE_CONTRACT=contract-from-truffle-migrate
	$ export REGISTERED_ACCOUNT=sofie_offer_marketplace_cli
	$ offer-marketplace-cli --manager add-request "in 5 minutes" 1000 0
	$ offer-marketplace-cli list

Keep in mind that you should use `SET` instead of `export` in Windows.

#### Flask backend

The backend APIs built with Flask are still under active development, and will be completed in the near future. For now, the endpoints related to the requests and offers and other extra information are not connected to the Marketplace smart contracts.

The backend is implemented by using `FlaskRESTful`. For running
the backend, first you should set its environment variable to located package:

    $ export FLASK_APP=sofie_offer_marketplace.backend

After this step, you can use the command below to run it:

    $ flask run

### Deployment

The demo backend describes an example how to deploy the component. You can 
find more information about deployment in the [demo/README.md](demo/README.md) file.


### Re-using the template

This project can be extended in multiple ways. The recommended way is
to use this project as a *dependency* in your own project, and re-use
these components via imports or other references (depending on whether
you are working on Python or Solidity parts of the code).

* Most of the primary code is designed to be loosely coupled and
  re-usable. Thus while the examples use Flask for building web
  services, the core itself is modularized as a Python library
  and should be re-usable in other environments.

### Docker image

Execute the script `docker-build.sh` to build docker image for the Marketplace component. The Docker image contains the backend listening globally at port 5000. 

***

## Testing

The `tests/marketplace` directory contains the scripts to unit test the backend.
The `solidity/test/` directory contains the scripts to unit test the smart contracts.

### Prerequisites

Tests for the Python components can be run either by using Tox, which will install all dependencies automatically, or directly using pytest, which can be used to run independent tests.

Install Tox:

    $ pip install tox


Or install pytest and dependencies:

    $ pip install pytest pytest-asyncio pytest-mock pytest-mypy

    
To test example smart contracts, install Truffle:

    $ cd solidity/
    $ npm install


### Running the tests

To test the Python components run either:
```bash
tox
```

Or:
```bash
pytest -v
mypy src tests
```

To test the smart contracts located in `solidity` directory (it compiles them automatically):

    $ make test-contracts

The provided makefile has simple targets to test all of the parts.

	$ make test


### Evaluating the results

When using Tox and Truffle, test results in JUnit format are stored in `tests` directory. Files `backend_test_results.xml`, `backend_mypy_test_results.xml`, and `smart_contracts_test_results.xml` contain results for the backend tests, backend mypy (static type checked) tests, and smart contracts tests respectively.

***

## Known and Open issues

- Some necessary events are not emitted

When a request is closed, an event with data payload carrying the request and corresponding selected offer information should be emitted for external applications.

- Check on request open status

The open status of a request should be checked before the actual processing in the `closeRequest` and `deleteRequest` method, so that proper event can be used to signal the contract user.

***

## Future Work

- Event callbacks in backend.

A flexible event callback utility is needed in the backend, so that the application logic can subscribe to the events emitted by the Marketplace smart contracts, and take customized actions.

- The Flask backend needs to be implemented

For the moment, the implementation of the Flask backend API are still under development and will be ready in the near future.

***

## Generating documentation for Python code

We use a mix of markdown and reStructuredText format for documenting
the project. Python code documentation is autogenerated by using
Sphinx. You can see the `md` and `rst` files in the `doc`
directory. To generate the documentation you should install `sphinx`
and the various sphinx extensions that are used:

    $ pip install sphinx m2r sphinxcontrib-httpdomain sphinxcontrib-soliditydomain sphinxcontrib-seqdiag

Now you can run

    $ make html

to generate documentation. Generated documentation is saved in
`doc/html`. `index.html` is the main page and you can find all
documentations by its links.

***

## Contact info

**Contact**: Wu, Lei lei.1.wu@aalto.fi

**Contributors**: can be found in [authors](AUTHORS) file.

***

## License

This component is licensed under the Apache License 2.0.
