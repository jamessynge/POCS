#!/bin/bash -e

THIS_DIR="$(dirname "$(readlink -f "${0}")")"

source "${CONDA_SH}"

echo "Adding extra channels to conda"
conda config --prepend channels astropy
conda config --append channels conda-forge
conda config --show channels
conda info

# Channels are listed from least preferred to most preferred.
# As a result packages in more preferred channels will replace
# those installed earlier (happens a lot due to conda-forge
# having many packages that the others have, and conda automatically
# installing packages on which other packages depend).

echo
echo "Installing packages into panoptes-env."
conda install -n panoptes-env --yes --quiet \
        "--file=${THIS_DIR}/astropy.conda-channel-packages.txt" \
        "--file=${THIS_DIR}/anaconda.conda-channel-packages.txt" \
        "--file=${THIS_DIR}/conda-forge.conda-channel-packages.txt"

# for CHANNEL in conda-forge anaconda astropy ; do
#   echo
#   echo "Installing packages from channel ${CHANNEL} into panoptes-env."
#   conda install -n panoptes-env --channel "${CHANNEL}" --yes --quiet \
#         "--file=${THIS_DIR}/${CHANNEL}.conda-channel-packages.txt"
# done
