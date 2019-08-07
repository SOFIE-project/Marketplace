all: compile

compile:
	cd solidity && truffle compile

test:
	tox
	cd solidity && truffle test

html:
	cd doc && make html