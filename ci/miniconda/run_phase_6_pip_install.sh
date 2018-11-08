#!/bin/bash -e

source "${CONDA_SH}"
conda activate panoptes-env

echo "Upgrading pip before installing non-conda, pure-python packages."
pip install --quiet --upgrade pip

echo
echo "Installing python packages using pip."
pip install --quiet --requirement requirements.txt
