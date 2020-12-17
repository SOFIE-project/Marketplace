all build: build-contracts build-python build-container

all-ci all-dev build-dev: build-contracts build-container
	python3 setup.py develop

build-contracts:
	cd solidity && (npm install && npx truffle compile)

build-python:
	python3 setup.py build

build-container:
	DOCKER_BUILDKIT=1 docker build -t offer-marketplace .

migrate:
	cd solidity && npx truffle migrate --reset --f 3 --to 3 --network marketplace

with-compose:
	@if [ -z "$$TARGET" ]; then echo "Error: TARGET must be specified"; exit 1; fi
	docker-compose up -d ganache
	@echo "Waiting for Ganache to start..."

# test that Ganache is running before migrating smart contracts
	@until curl -s -X POST --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' http://localhost:7545 >/dev/null; do sleep 1; done
	$(MAKE) migrate

# update configuration for both host and Celery container
	sh ./update_config.sh solidity/build/contracts/FlowerMarketPlace.json http://localhost:7545 test.cfg
	sed 's/^url=.*/url=http:\/\/ganache:7545/' test.cfg > test_compose.cfg

	docker-compose build celery
	MARKETPLACE_CONFIG=test_compose.cfg docker-compose up -d celery
	sleep 5

	$(MAKE) $(TARGET); ret=$$?; docker-compose logs; docker-compose down -v; exit $$ret

# test-success and test-failure for testing with-compose target itself
test-success:
	exit 0
test-failure:
	exit 1

test-tox:
	tox -e py36

test-tox-py38:
	tox -e py38

test:: export MARKETPLACE_CONFIG=test.cfg
test::
	$(MAKE) with-compose TARGET="test-tox"

test:: test-contracts

test-ci:: export MARKETPLACE_CONFIG=test.cfg
test-ci::
	$(MAKE) with-compose TARGET="test-tox-py38"

test-ci:: test-contracts

test-contracts:
	cd solidity && npx truffle test

clean:
	-python3 setup.py clean
	-cd solidity && rm -rf node_modules
	-docker-compose down -v
	-rm -f tests/*test_results.xml

html:
	cd doc && make html

html-watch: html
	while fswatch -1 -e '/\.' -e 'flymake' doc; do $(MAKE) html; done
