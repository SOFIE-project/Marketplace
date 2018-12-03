Offer Marketplace
=================

This repository contains a **template** that implements the *Offer
Marketplace* business platform as described as part of the SOFIE
project's [Business Platforms
document](https://media.voog.com/0000/0042/0957/files/SOFIE_D3.2-Business_Platform_Lab_Prototype_Release.pdf).

# How to use this template?

## Testing out the sample marketplace

TBD --- have instructions here on how to use the sample code and
deployment scripts to deploy the sample marketplace

## Re-using the template

This project can be extended in multiple ways. The recommended way is
to use this project as a *dependency* in your own project, and re-use
these components via imports or other references (depending on whether
you are working on Python or Solidity parts of the code).

* Most of the primary code is designed to be loosely coupled and
  re-usable. Thus while the examples use Flask for building web
  services, the core itself is modularized as library a Python library
  and should be re-usable in other environments.

# Documentation

TBD --- API documentation somewhere (readthedocs or similar?)

The project's technical design and architecture documentation (as well
as other stuff) can be found in the [doc](/doc/README.md) directory.

# Building and running local tests

You probably should use `pyenv`, but the setup.py should work
regardless normally. For testing, just run:

	$ python setup.py test

Although since this tree uses py.test and tox, running any of the
following should *approximately* run the same test suite (apart from
environment and python version differences):

	$ py.test
	$ tox

For testing out the flower marketplace tool `flower.py`, you need
first to set up the environment. First, set up truffle and a local
ethereum node (Ganache, for example), then:

	$ (cd solidity && truffle migrate)
	$ export WEB_PROVIDER_URI=http://localhost:7545
	$ export FLOWER_ACCOUNT=account-id-from-ganache-console
	$ export FLOWER_CONTRACT=contract-from-truffle-migrate
	$ python flower.py --manager add-request 1000 0 'in 5 minutes'
	$ python flower.py list

# Testing

The provided makefile has simple targets to test all of the
parts. Remember that you will need ganache or other Ethereum network
environment to run Truffle tests (in `solidity` directory).

	$ make all
	$ make test

# License

This project is under the Apache License 2.0.
