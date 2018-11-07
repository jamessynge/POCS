#!/bin/bash -ex

# Install miniconda, but no additional packages, into PANDIR.

echo
echo "Installing miniconda. License at: https://conda.io/docs/license.html"
local -r the_script="${PANDIR}/tmp/miniconda.sh"
mkdir -p "$(dirname "${the_script}")"
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
-O "${the_script}"
bash "${the_script}" -b -p "${CONDA_INSTALL_DIR}"
rm "${the_script}"

