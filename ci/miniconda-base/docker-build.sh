#!/bin/bash -ex

# Build this docker image. If running multiple times, you can speed things
# up by running an apt caching proxy:
#
#       $POCS/scripts/install/run-apt-cache-ng-in-docker.sh
#       APT_PROXY_PORT=3142 ./docker-build.sh

[ -d "${POCS}" ] || (echo "POCS is not defined!" && exit 1)
[ -d "${PANDIR}" ] || (echo "PANDIR is not defined!" && exit 1)

THIS_DIR="$(dirname "$(readlink -f "${0}")")"
THIS_LEAF_DIR="$(basename "${THIS_DIR}")"

# Build the core of the command.

CMD="docker build --build-arg apt_proxy_port=$APT_PROXY_PORT"

CURRENT_USER="$(id -u -n)"
if [ "$1" == "--as-me" -a "${CURRENT_USER}" != "root" ] ; then
  TAG_BASE="panoptes-${CURRENT_USER}"
  CMD+=" --build-arg pan_user=$CURRENT_USER"
  CMD+=" --build-arg pan_user_id=$(id -u)"
  CMD+=" --build-arg pan_group=$(id -g -n)"
  CMD+=" --build-arg pan_group_id=$(id -g)"
elif [ "$1" == "--as-panoptes" ] ; then
  PANOPTES_USER="$(id -u -n panoptes 2>/dev/null || /bin/true)"
  if [ -z "${PANOPTES_USER}" ] ; then
    echo "There is no 'panoptes' user!"
    exit 1
  fi
  TAG_BASE="panoptes-panoptes"
  CMD+=" --build-arg pan_user=$(id -u -n panoptes)"
  CMD+=" --build-arg pan_user_id=$(id -u panoptes)"
  CMD+=" --build-arg pan_group=$(id -g -n panoptes)"
  CMD+=" --build-arg pan_group_id=$(id -g panoptes)"
elif [ "$1" == "" -o "$1" == "--as-root" ] ; then
  TAG_BASE="panoptes"
  CMD+=" --build-arg pan_user=root"
  CMD+=" --build-arg pan_user_id="
  CMD+=" --build-arg pan_group="
  CMD+=" --build-arg pan_group_id="
else
  echo "Unknown option: $1"
  exit 1
fi

TAG="${TAG_BASE}/${THIS_LEAF_DIR}"

# Create a temporary directory into which to copy the context for the
# docker build command, and arrange for that directory to be cleaned up
# at the end of this script.
timestamp="$(date "+%Y%m%d.%H%M%S")"
temp_dir=$(mktemp --tmpdir --directory docker-build.${THIS_LEAF_DIR}.${timestamp}.XXXX)
function clean_temp_dir {
  rm -rf "${temp_dir}"
}
trap clean_temp_dir EXIT

echo "Creating docker build context in ${temp_dir}"

cp -t "${temp_dir}" \
  "${POCS}"/requirements.txt \
  "${THIS_DIR}"/run_* \
  "${POCS}"/scripts/install/*

echo "Building docker image: ${TAG}"

$CMD --tag "${TAG}" --file "${THIS_DIR}"/Dockerfile -- "${temp_dir}"
