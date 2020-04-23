FROM python:3.6-alpine

RUN apk add --no-cache gcc musl-dev

COPY ./ /var/offer-marketplace/

WORKDIR /var/offer-marketplace
RUN python3 setup.py build && python3 setup.py install

ENV FLASK_APP=sofie_offer_marketplace.backend
CMD ["flask", "run", "-h", "0.0.0.0"]
