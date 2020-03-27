#!/bin/bash

set -euf -o pipefail
set -x

SEASON="$1"
SENSORS_FILE="$2"
DATE="$3"

cat "${SENSORS_FILE}" \
  | xargs -L 1 -I % /irods_vault/.tmp/bin/tar-dataset.sh "${SEASON}" % "${DATE}"
