from flask import Flask, Blueprint, render_template, session
from flask import current_app, redirect, url_for, request
from functools import wraps
import json


root = Blueprint('root', __name__)


def create_app():
    app = Flask(__name__)

    app.config.from_object('server.settings.default_settings')
    app.config.from_envvar('DEMO_SETTINGS', silent=True)

    app.register_blueprint(root)
    # TODO register be at /api

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
