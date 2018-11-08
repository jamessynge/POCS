#!/bin/bash -e

source "${CONDA_SH}"

# Remove tarballs and packages downloaded but not in use.
du -s -h "${CONDA_INSTALL_DIR}"
conda clean --tarballs --packages 
du -s -h "${CONDA_INSTALL_DIR}"
conda clean --all 
du -s -h "${CONDA_INSTALL_DIR}"
