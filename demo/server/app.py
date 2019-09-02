from flask import Flask, Blueprint, render_template, session, abort
from flask import current_app, redirect, url_for, request, jsonify
from functools import wraps
import json


root = Blueprint('root', __name__)
api = Blueprint('api', __name__)  # to be replaced with OM BE API blueprint


def create_app():
    app = Flask(__name__)

    app.config.from_object('server.settings.default_settings')
    app.config.from_envvar('DEMO_SETTINGS', silent=True)

    app.register_blueprint(root)
    # TODO register be at /api
    app.register_blueprint(api, url_prefix='/api')

    return app


def roles(*roles):
    def decorator(f):
        @wraps(f)
        def check_roles(*args, **kwargs):
            role = session['role']
            if role == 'unknown' or roles and role not in roles:
                return redirect(url_for('root.index'))

            return f(*args, **kwargs)
        return check_roles
    return decorator


@root.context_processor
def inject_info():
    # TODO: contract address, network, type from the actual contract
    return dict(
        marketplace_contract=None,
        marketplace_network=None,
        marketplace_type=None)


@root.before_request
def permanent_session():
    session.permanent = True
    session.setdefault('role', 'unknown')


@root.route('/')
def index():
    session.role = 'unknown'

    return render_template('index.html')


@root.route('/', methods=['PUT', 'POST'])
def update_role():
    role = request.values.get('role')
    if role in ('manager', 'bidder', 'anonymous'):
        session['role'] = role
        return redirect(url_for('root.list_requests'))
    return redirect(url_for('root.index'))


@root.route('/requests')
@roles()
def list_requests():
    return render_template('requests.html')


@root.route('/request/<int:id>')
@roles()
def show_request(id: int):
    return render_template('requests.html',
                           request_id=id)


@root.route('/request/new')
@roles('manager')
def new_request():
    return render_template('new_request.html')


@root.route('/request/<int:id>/decide')
@roles('manager')
def decide_request(id: int):
    return render_template('decide_request.html',
                           request_id=id)


@root.route('/request/<int:id>/offer')
@roles('bidder')
def new_offer(id: int):
    return render_template('new_offer.html',
                           request_id=id)


########################################################################

# dummy api results

requests = {
    1: dict(id=1, state="decided",
            decision=[dict(id=1, extra=dict(quantity=8)),
                      dict(id=2, extra=dict(quantity=2))],
            creator="0x123123123",
            created="2018-12-1T12:00:00",
            deadline="2019-01-01T00:00:00",
            offers=[dict(id=1), dict(id=2), dict(id=3)],
            extra=dict(quantity=10, variety="rosamunda")),
    2: dict(id=2, state="open", decision=None,
            creator="0x123123123",
            created="2018-12-28T12:00:00",
            deadline="2020-01-01T00:00:00",
            offers=[dict(id=4)],
            extra=dict(quantity=51, variety="siikli"))
}

offers = {
    1: dict(id=1, request=dict(id=1),
            created="2018-12-12T12:00:00",
            creator="0x1234",
            extra=dict(min=8, max=8, price=1020)),
    2: dict(id=2, request=dict(id=1),
            created="2018-12-12T12:00:00",
            creator="0x4321",
            extra=dict(min=1, max=5, price=910)),
    3: dict(id=3, request=dict(id=1),
            created="2018-12-12T12:00:00",
            creator="0x5678",
            extra=dict(min=1, max=1, price=800)),
    4: dict(id=4, request=dict(id=2),
            created="2018-12-12T12:00:00",
            creator="0x8765",
            extra=dict(min=20, max=20, price=1600)),
}


@api.route('/info')
def api_info():
    return jsonify({
        "type": "eu.sofie-iot.demo_marketplace",
        "contract": {
            "address": "0x6457AC5F9F8676B9223dE791571C5E8f86F1db13",
            "network": 4
        }
    })


@api.route('/request/')
def api_requests():
    return jsonify({"requests": list(requests.values())})


@api.route('/request/<int:request_id>')
def api_request(request_id):
    if request_id not in requests:
        abort(404)
    return jsonify(requests[request_id])


@api.route('/offer/')
def api_offers():
    return jsonify({"offers": list(offers.values())})


@api.route('/offer/<int:offer_id>')
def api_offer(offer_id):
    if offer_id not in offers:
        abort(404)
    return jsonify(offers[offer_id])
