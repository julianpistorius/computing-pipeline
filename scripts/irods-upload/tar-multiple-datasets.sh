#!/bin/bash

set -euf -o pipefail
set -x

SEASON="$1"
SENSORS_FILE="$2"
DATES_FILE="$3"

cat "${DATES_FILE}" \
  | xargs -L 1 -I % /irods_vault/.tmp/bin/tar-multiple-sensors.sh "${SEASON}" "${SENSORS_FILE}" %
