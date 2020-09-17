FROM python:3.6 AS build

RUN apt-get update && apt-get -y install gcc

COPY ./ /var/marketplace/

WORKDIR /var/marketplace
RUN python3 setup.py build && python3 setup.py install

ENV FLASK_APP=sofie_offer_marketplace.backend
CMD ["flask", "run", "-h", "0.0.0.0"]
