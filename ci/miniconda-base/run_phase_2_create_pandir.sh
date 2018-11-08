#!/bin/bash -ex

mkdir -p "${PANDIR}"
if [ -z "${PANUSER}" -o "${PANUSER}" == "$(id -u -n)" ] ; then
  echo "Not setting or changing the ownership of ${PANDIR}."
  exit 0
fi

CMD="chown -R ${PANUSER}"
if [ -n "${PANGROUP}" ] ; then
  CMD+=":${PANGROUP}"
fi

$CMD "${PANDIR}"
