# Backend Development Documentation

## Environment set up

Enter the proper virtual environment with Python 3.6+.

```
python3 -m venv venv
source venv/bin/activate
```

Build the application and install the dependencies, in the virtual environment above (Python 3).

```
python setup.py build
python setup.py install
```


First, set the environment variables for development, including the module for the Flask application and configurate its mode to be development. 

```
export FLASK_APP=src/sofie_offer_marketplace.backend.app
export FLASK_ENV=development
```

## Blockchain set up

For development, a local Ethereum test network needs to be set up with the Ganache tool. 

```
ganache-cli -p 7545 -b 1
```

Afterwards, the specified smart contract of the marketplace application, in this case the `FlowerMarketplace` should be deployed upon it, as the following.

```
make migrate
```

## Run server

Now, under the virtual environment, it is available to get the development server running, as the following.

```
python -m flask run
```

To provide customized configuration file, the Flask app can lauched as follows.

```
python src/sofie_offer_marketplace/backend/app.py <customized-configuration-file>
```

### Launch Celery worker for event callbacks

To use the event call backs features, a separate Celery worker needs be launched to handle the background jobs.

First, run a Redis in the background from Docker as the message broker.

```
docker run -d -p 6379:6379 redis
```

Then the celery worker can be launched as follows.

```
celery -A sofie_offer_marketplace.backend.app.celery worker --loglevel=INFO
```

## System test

With all the steps taken as above, the system test can be carried out by the simple command below.

```
tox -v
```

Separate run of the backend related tests with pytest are also available, as below in the virtual environment.

```
python -m pytest -s tests/marketplace/test_backend.py
python -m pytest -s tests/marketplace/test_event_callbacks.py
```

or separate visit of the endpoints of the backend APIs.

```
curl localhost:5000/info
```