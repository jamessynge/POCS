#!/bin/bash -ex

# Explanation of docker run flags:
#   --rm    Automatically remove the container when it exits.
#   --env   Export an environment variable to the program running in the container.
#   --volume  Bind mount a volume 

IMAGE_TO_RUN="panoptes/local-image"

# We run as root and later drop permissions. This is required to setup the USER
# in useradd below, which is need for correct Python execution in the Docker
# environment.

MY_UID=$(id -u)
MY_GID=$(id -g)



docker run -it \
  --volume "${POCS}:/var/panoptes/POCS" \
  "${IMAGE_TO_RUN}"




# # We run as root and later drop permissions. This is required to setup the USER
# # in useradd below, which is need for correct Python execution in the Docker
# # environment.
# USER=root
# USER_GROUP=root

# [[ -z "${IMAGE_NAME}" ]] && IMAGE_NAME="envoyproxy/envoy-build-ubuntu"
# # The IMAGE_ID defaults to the CI hash but can be set to an arbitrary image ID (found with 'docker
# # images').
# [[ -z "${IMAGE_ID}" ]] && IMAGE_ID="${ENVOY_BUILD_SHA}"
# [[ -z "${ENVOY_DOCKER_BUILD_DIR}" ]] && ENVOY_DOCKER_BUILD_DIR=/tmp/envoy-docker-build

# mkdir -p "${ENVOY_DOCKER_BUILD_DIR}"
# # Since we specify an explicit hash, docker-run will pull from the remote repo if missing.
# docker run --rm -t -i -e HTTP_PROXY=${http_proxy} -e HTTPS_PROXY=${https_proxy} \
#   -u "${USER}":"${USER_GROUP}" -v "${ENVOY_DOCKER_BUILD_DIR}":/build \
#   -v "$PWD":/source -e NUM_CPUS --cap-add SYS_PTRACE --cap-add NET_RAW --cap-add NET_ADMIN "${IMAGE_NAME}":"${IMAGE_ID}" \
#   /bin/bash -lc "groupadd --gid $(id -g) -f envoygroup && useradd -o --uid $(id -u) --gid $(id -g) --no-create-home \
#   --home-dir /source envoybuild && usermod -a -G pcap envoybuild && su envoybuild -c \"cd source && $*\""
