#!/bin/bash -e

source "${CONDA_SH}"

# Remove tarballs downloaded in order to install packages..
du -s -h "${CONDA_INSTALL_DIR}"
conda clean --yes --tarballs
du -s -h "${CONDA_INSTALL_DIR}"
