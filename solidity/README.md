Flower and Beach Chair Marketplaces
=================

This repository contains the implementation of some sample **Offer Marketplace**s, called **Flower Marketplace**, and **Beach Chair Marketplace**.

The FlowerMarketPlace and BeachChairMarketPlace contracts reside in contracts directory. Also test files for the contracts exist in test directory.

Truffle framework is used for the developing, deploying, and testing contracts.

Currently the default version of Truffle is used in the project, which is very easy to install and work with. Here, I will explain how to use Truffle in order to run and test contracts. It is possible that we customize truffle in future, in order to make it compatible with our needs. I will add instructions on using the modified Truffle when (and if) it was needed in the future. You can also gain additional information on how to use Truffle in [its website] (https://truffleframework.com/).

## Installation

You can simply install Truffle with the command below:

```
$ npm install -g truffle
```

NodeJS 5.0+ is recommended for the installation of Truffle.

## Compilation

You can compile the contracts with the following command:

```
$ truffle compile
```
It will create the required json files within the build directory.

You might need to remove the previous build directory beforehand:

```
$ rm -r build/
```

## Migration

Then you can run migration files using the below command:

```
$ truffle migrate
```

## Testing

Finally you can run tests using the following command:

```
$ truffle test
```
