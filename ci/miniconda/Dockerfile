# PANOPTES Miniconda Base Dependencies Container
# Build with:
#
#         ./docker-build.sh
#
# Note that specifying a group by ID only (pan_group_id) won't work properly.

FROM debian:stable-slim as build-env

LABEL description="PANOPTES Miniconda Base Dependencies Container"
LABEL author="Developers for PANOPTES project"
LABEL url="https://github.com/panoptes/POCS"

ARG apt_proxy_port=
ARG pan_dir=/var/panoptes
ARG pan_user=root
ARG pan_user_id=
ARG pan_group=root
ARG pan_group_id=

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV ENV /root/.bashrc
ENV SHELL /bin/bash
ENV PANDIR $pan_dir
ENV PANUSER $pan_user
ENV CONDA_INSTALL_DIR ${PANDIR}/miniconda
ENV CONDA_SH ${CONDA_INSTALL_DIR}/etc/profile.d/conda.sh

# Set the WORKDIR to a directory we can blow away at the end.
WORKDIR /workdir

# Testing script, should you need it.
# COPY run_phase_0_test.sh /workdir/
# RUN /workdir/run_phase_0_test.sh && \
#     rm -rf /workdir

################################################################################
# If there is an apt caching proxy running, tell apt where to find it. Note
# that this persists in an /etc/apt/... file, so isn't dependent on the ARG
# in the future, for good or ill.

COPY detect-apt-cache.sh /workdir/
RUN APT_PROXY_PORT=$apt_proxy_port /workdir/detect-apt-cache.sh && \
    rm -rf /workdir

################################################################################
# Install linux packages needed in order to *install* or run miniconda.

COPY run_phase_1_apt_deps.sh /workdir/
RUN /workdir/run_phase_1_apt_deps.sh && \
    rm -rf /workdir

################################################################################
# Create user PANUSER.

COPY create-panoptes-user.sh /workdir/
RUN PANUSER=$pan_user PANUSER_ID=$pan_user_id \
    PANGROUP=$pan_group PANGROUP_ID=$pan_group_id NO_PASSWORD=true \
    /workdir/create-panoptes-user.sh && \
    rm -rf /workdir

################################################################################
# Make the directory to be owned by PANUSER.

COPY run_phase_2_create_pandir.sh /workdir/
RUN PANGROUP=$pan_group /workdir/run_phase_2_create_pandir.sh && \
    rm -rf /workdir

################################################################################
# COPY does so as root:root unless you tell it otherwise, and COPY doesn't
# expand ARG or ENV values, so literals are required. This means that we can't
# substitute $pan_user or $PANUSER into the COPY command, so this means that
# COPY will only produce files owned by root:root in our scenario. We could
# copy all of the files from the context into the WORKDIR at once and change
# the ownership of all files, but that means that changing any file in the
# context causes the COPY layer to be different, so caching fails.
#
# Therefore we are copying just the files we need here, then changing ownership
# and user. A macro could be useful here. Or just wait until things are stable
# and collapse operations into a very few scripts.
################################################################################
# As PANUSER, install miniconda, but no additional packages.

USER root
COPY run_phase_3_miniconda_base.sh /workdir/
RUN chown -R $pan_user:$pan_group /workdir
USER $PANUSER
RUN APT_PROXY_PORT=$apt_proxy_port /workdir/run_phase_3_miniconda_base.sh
USER root
RUN rm -rf /workdir

################################################################################
# Create the panoptes environment.

COPY run_phase_4_bare_panoptes_env.sh /workdir/
RUN chown -R $pan_user:$pan_group /workdir
USER $PANUSER
RUN /workdir/run_phase_4_bare_panoptes_env.sh
USER root
RUN rm -rf /workdir

################################################################################
# Load the panoptes environment with packages.

COPY run_phase_5_grow_panoptes_env.sh *.conda-channel-packages.txt /workdir/
RUN chown -R $pan_user:$pan_group /workdir
USER $PANUSER
RUN /workdir/run_phase_5_grow_panoptes_env.sh
USER root
RUN rm -rf /workdir

################################################################################
# Install pip packages.

COPY run_phase_6_pip_install.sh requirements.txt /workdir/
RUN chown -R $pan_user:$pan_group /workdir
USER $PANUSER
RUN /workdir/run_phase_6_pip_install.sh
USER root
RUN rm -rf /workdir

################################################################################
# Remove tarballs downloaded for installation, but no longer needed.

COPY run_phase_7_conda_clean.sh /workdir/
RUN chown -R $pan_user:$pan_group /workdir
USER $PANUSER
RUN /workdir/run_phase_7_conda_clean.sh
USER root
RUN rm -rf /workdir

# Done!

RUN rm -rf /root/.cache /root/.conda
WORKDIR $pan_dir
USER $pan_user

CMD ["/bin/bash"]
