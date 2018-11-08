#!/bin/bash -ex

source "${CONDA_SH}"
conda info
conda config --show channels
conda config --prepend channels astropy
conda config --append channels conda-forge

exit 1

echo
echo "Installing miniconda. License at: https://conda.io/docs/license.html"
the_script="${PANDIR}/tmp/miniconda.sh"
mkdir -p "$(dirname "${the_script}")"
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
-O "${the_script}"
bash "${the_script}" -b -p "${CONDA_INSTALL_DIR}"
rm "${the_script}"

# Check that things are working

source ${CONDA_INSTALL_DIR}/etc/profile.d/conda.sh