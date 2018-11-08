#!/bin/bash -e

# Python 3.6 works around a problem building astroscrappy in 3.7.
PYTHON_VERSION="${PYTHON_VERSION:-3.6}"

source "${CONDA_SH}"

echo
echo "Creating conda environment 'panoptes-env' with Python ${PYTHON_VERSION}"
conda create -n panoptes-env --yes --quiet "python=${PYTHON_VERSION}"
conda update -n panoptes-env --all
