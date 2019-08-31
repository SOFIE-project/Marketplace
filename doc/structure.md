Code and directory structure
============================

Since this is intended to be re-usable code, with the repository
containing sample stuff, we want to have a clear distinction between
these two code groups.

For this purpose the top-level project directory is structured as
follows:

* `src/sofie_offer_marketplace`

  This is the actual python package code that implements a generic
  offer marketplace interface.

* `src/sofie_offer_marketplace_cli`

  This contains a command line tool that uses the generic interface,
  and tries to be applicable in as many situations as possible.

* `solidity`

  Contains the actual solidity code, including `solidity/contracts`
  for the contracts and tests in `solidity/tests`.

* `doc`

  Project documentation
