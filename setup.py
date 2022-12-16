from setuptools import setup, find_packages

# TODO:
#
# * This blindly bundles together the library
#   (sofie_offer_marketplace), the Flask-based REST service stub
#   (sofie_offer_marketplace_service) and the sample UI
#   (sofie_offer_marketplace_ui). These should be bundled separately,
#   OTOH, at this early development phase just for simplicity these
#   have been bundled into this single setup.py. E.g. to fix this,
#   make sure the lib is independent and does not include flask
#   etc. dependencies at all, and so on for the others.

setup(
    name='sofie_offer_marketplace',
    version='0.1',
    description=(
        'Template implementation of the SOFIE project\'s '
        'Offer Marketplace business platform'
    ),
    url='https://version.aalto.fi/gitlab/sofie/open-source/offer-marketplace',
    author='SOFIE Project',
    author_email='sofie-offer-marketplace@sofie-iot.eu',
    license='APL 2.0',
    package_dir={'': 'src'},
    packages=find_packages(where='src'),
    ## There is nothing as-of in the reference platform, so keeping
    ## this commented.
    # dependency_links=['git+ssh://git@version.aalto.fi/sofie/open-source/reference-platform.git#egg=sofie_reference_platform-0.1'],
    install_requires=[
        # 'sofie_reference_platform',
        'flask-restful==0.3.8',
        'web3==5.13.0',
        'dateparser==1.0.0',  # for offer-marketplace-cli
        # 'kombu<5.0.2', # for backend
        'celery==5.0.4', # for backend
        'redis==3.5.3', # backend
        'eth-hash<0.4.0', # backend
        'flask==1.1.4', # backend
        'eth-rlp<0.3.0', # backend
        'markupsafe==2.0.1', # backend
        #'click==7.1.2',
        # 'click-didyoumean==0.0.3',
        # 'click-repl==0.1.6',
    ],
    entry_points={
        'console_scripts': ['offer-marketplace-cli=sofie_offer_marketplace_cli:main']
    },
    tests_require=['pytest', 'pytest-asyncio', 'pytest-mock'],
    setup_requires=['tox-setuptools'],
    zip_safe=False)
