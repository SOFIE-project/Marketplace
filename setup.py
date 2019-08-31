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
        'Flask',
        'web3',
        'dateparser',  # for offer-marketplace-cli
    ],
    entry_points={
        'console_scripts': ['offer-marketplace-cli=sofie_offer_marketplace_cli:main']
    },
    tests_require=['pytest', 'pytest-asyncio', 'pytest-mock'],
    setup_requires=['tox-setuptools'],
    zip_safe=False)
