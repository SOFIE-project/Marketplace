all: compile

compile:
	cd solidity && npx truffle compile

test:
	tox
	cd solidity && npx truffle test

test-contracts:
	cd solidity && npx truffle test

html:
	cd doc && make html

html-watch: html
	while fswatch -1 -e '/\.' -e 'flymake' doc; do $(MAKE) html; done
