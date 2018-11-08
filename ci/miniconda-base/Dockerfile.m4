ifdef(`COMMENT', `
This M4 macro input file checks for these tokens:

apt_proxy_port - If set then detects the caching proxy for speeding apt.
pan_dir - Assigned to PANDIR; defaults to /var/panoptes
pan_user - Name of user to be created. Could be current user or even root.
pan_user_id - Identifier (integer) of the user to be created. 0 if root.
pan_group
pan_group_id

')dnl
# PANOPTES Miniconda Base Dependencies Container
# Build with:
#
#         ./docker-build.sh
#
# Note that specifying a group by ID only (pan_group_id) won't work properly.

dnl `apt_proxy_port'=dumpdef(`apt_proxy_port')
dnl apt_proxy_port=dumpdef(`apt_proxy_port')

FROM debian:stable-slim as build-env

LABEL description="PANOPTES Miniconda Base Dependencies Container"
LABEL author="Developers for PANOPTES project"
LABEL url="https://github.com/panoptes/POCS"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV ENV /root/.bashrc
ENV SHELL /bin/bash
ENV PANDIR pan_dir
ifdef(`pan_user',ENV PANUSER pan_user
,)dnl

# Set the WORKDIR to a directory we can blow away at the end.

WORKDIR /workdir

ifdef(`apt_proxy_port',
# Tell apt where to find the caching proxy. Note that this persists
# in an /etc/apt/... file, so isn't dependent on the ARG
# in the future, for good or ill.

COPY detect-apt-cache.sh .
RUN APT_PROXY_PORT=apt_proxy_port ./detect-apt-cache.sh && \
    rm detect-apt-cache.sh

)dnl
# Install linux packages needed in order to install or to run miniconda.
ifdef(`apt_proxy_port',,dnl
# No APT caching proxy provided, so installing will require downloading
# everytime.
)dnl

COPY run_phase_1_apt_deps.sh .
RUN ./run_phase_1_apt_deps.sh && rm run_phase_1_apt_deps.sh

ifdef(`pan_user',
# Create user PANUSER.

COPY create-panoptes-user.sh .
RUN PANUSER=pan_user PANUSER_ID=pan_user_id \
    PANGROUP=pan_group PANGROUP_ID=pan_group_id \
    NO_PASSWORD=true ./create-panoptes-user.sh && rm create-panoptes-user.sh

# Make the PANDIR directory, owned by PANUSER.

COPY run_phase_2_create_pandir.sh .
RUN PANUSER=pan_user PANGROUP=pan_group \
    ./run_phase_2_create_pandir.sh && rm run_phase_2_create_pandir.sh

# Cleanup the WORKDIR used as user root, switch to operating as PANUSER in
# with the WORKDIR set to PANDIR panoptes. Note that COPY does so as
# root:root unless you tell it otherwise... which we do.

RUN rm -rf /workdir
USER pan_user
WORKDIR pan_dir

# As PANUSER, install miniconda, but no additional packages.

COPY --chown=$pan_user:$pan_group run_phase_3_miniconda_base.sh .
RUN ./run_phase_3_miniconda_base.sh && rm run_phase_3_miniconda_base.sh





,
# Make the PANDIR directory.

RUN mkdir -p $PANDIR ; ls -l $PANDIR
)
################################################################################
# Cleanup the workdir used as user root, switch to operating as PANUSER in
# /var/panoptes. Note that COPY does so as root:root unless you tell it
# otherwise.

RUN rm -rf /workdir
USER pan_user
WORKDIR pan_dir

################################################################################
# As PANUSER, install miniconda, but no additional packages.

COPY --chown=$pan_user:$pan_group run_phase_3_miniconda_base.sh .
RUN ./run_phase_3_miniconda_base.sh && rm run_phase_3_miniconda_base.sh

RUN exit 1

################################################################################
# Now install dependencies that are more likely to change (both the actual list
# of packages, their versions and installation flags).

COPY run_phase_2_apt_extras.sh .
RUN ./run_phase_2_apt_extras.sh && rm run_phase_2_apt_extras.sh

################################################################################
# Install miniconda and create the panoptes environment.
# This is broken up into multiple commands simply to aid in debugging the
# different steps of the build, exploiting docker's layer caching.

COPY *.conda-channel-packages.txt requirements.txt \
     install-miniconda.sh install-functions.sh

# First just get miniconda and the panoptes environment created.
RUN DO_INSTALL_CONDA_PACKAGES=0 DO_PIP_REQUIREMENTS=0 \
    ./install-miniconda.sh

# Then install conda packages, but not pip packages.
RUN DO_INSTALL_CONDA_PACKAGES=1 DO_PIP_REQUIREMENTS=0 \
    REQUIREMENTS_PATH=./requirements.txt \
    ./install-miniconda.sh

# Now install the pip packages.
RUN DO_INSTALL_CONDA_PACKAGES=0 DO_PIP_REQUIREMENTS=1 \
    REQUIREMENTS_PATH=./requirements.txt \
    ./install-miniconda.sh

################################################################################
# Copy the astrometry indices into place.

RUN rm -rf /usr/share/astrometry
COPY --from=panoptes/astrometry-indices /var/panoptes/astrometry/data/* /usr/share/astrometry/

################################################################################
# Copy in all the files from the context, which should be small in total size.
COPY * ./

################################################################################
# Create the directories that the installer expects to be there.
RUN ./create-core-panoptes-directories.sh

# This just sets up the environment variables and shell profiles for the user.
RUN ./install-dependencies.sh \
        --no-apt-get --no-mongodb --no-conda --no-conda-packages \
        --no-astrometry --no-astrometry-indices --no-pip-requirements

WORKDIR $POCS

RUN rm -rf /root/.cache /root/.conda /workdir

CMD ["/bin/bash"]
