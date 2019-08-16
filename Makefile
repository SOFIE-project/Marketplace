all: compile

compile:
	cd solidity && npx truffle compile

test:
	tox
	cd solidity && npx truffle test

html:
	cd doc && make html
