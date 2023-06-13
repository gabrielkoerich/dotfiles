#!/usr/bin/env bash

# Install Python and usefull stuff
brew install pkg-config libffi openssl python

# Instal python via brew or anaconda?

# Install Poetry https://python-poetry.org/docs/
curl -sSL https://install.python-poetry.org | python3 -

# env LDFLAGS="-L$(brew --prefix openssl)/lib" CFLAGS="-I$(brew --prefix openssl)/include" pip install cryptography==1.9
# pip install stronghold
pip install jupyterlab
pip install bt
pip install sanpy
# pip install qgrid
pip install jupyterlab_materialdarker
pip install -U quandl numpy pandas fbprophet matplotlib pytrends pystan
# jupyter nbextension enable --py --sys-prefix qgrid
# jupyter nbextension enable --py --sys-prefix widgetsnbextension
# jupyter labextension install @oriolmirosa/jupyterlab_materialdarker
# jupyter labextension install @jupyter-widgets/jupyterlab-manager
# jupyter labextension install qgrid
