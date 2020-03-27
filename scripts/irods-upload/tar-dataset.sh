#!/bin/bash

set -euf -o pipefail

RAW_DATA="/irods_vault/terraref-ds06/home/shared/terraref/ua-mac/raw_data"
UPLOADED_TARS_FILE="/var/lib/irods/uploaded-tars.tsv"
#SEASON="season_10"
#SENSOR="co2Sensor"
#DATASET="2020-02-04"
SEASON="$1"
SENSOR="$2"
DATASET="$3"
#export TMPDIR="/irods_vault/.tmp"
export TMPDIR="/var/cache/terraref-tars"
export OUTPUT_DIR="/irods_vault/terraref-ds06/home/shared/terraref/ua-mac/raw_tars/${SEASON}/${SENSOR}"
export IRODS_COLLECTION="/iplant/home/shared/terraref/ua-mac/raw_tars/${SEASON}/${SENSOR}"

# Constants:

E_NO_SENSOR_DATASET=1
E_SENSOR_DATASET_SCRATCH_EXISTS=2
E_SENSOR_DATASET_TAR_EXISTS=3

echoerr() { echo "$@" 1>&2; }

function log {
  logger --id --stderr --tag "$0" "$@"
  echoerr() { echo "$@" 1>&2; }
}

log "Check if tar process for $SENSOR/$DATASET has already been done"

# TODO: Check the tsv file for a sensor/dataset combination

log "Starting tar process for $SENSOR/$DATASET"

# Fail if sensor-dataset directory does not exist

SENSOR_DATASET_PATH="${RAW_DATA}/${SENSOR}/${DATASET}"

if [[ -d "$SENSOR_DATASET_PATH" ]]; then
  # All good.
  log "Found sensor-dataset directory: $SENSOR_DATASET_PATH"
else
  log "Error - No directory: $SENSOR_DATASET_PATH"
  exit "${E_NO_SENSOR_DATASET}"
fi

mkdir -p "${OUTPUT_DIR}"

# Fail if a final tar file for the sensor-dataset combo already exists

SENSOR_DATASET_FINAL_TAR_PATH="${OUTPUT_DIR}/${SENSOR}-${DATASET}.tar"

if [[ -f "${SENSOR_DATASET_FINAL_TAR_PATH}" ]]; then
  log "tar file for sensor dataset already exists"
  exit "${E_SENSOR_DATASET_TAR_EXISTS}"
else
  log "Final tar file for sensor dataset does not exist. Go ahead."
fi

# Clean up the temporary directory created
function finish {
  rmdir "$scratch"
}
trap finish EXIT

# Fail if a scratch directory for the sensor-dataset combo already exists

dir_count=$(find "$TMPDIR" -type d -name "tmp_"$SENSOR"_"$DATASET".*" | wc -l)
if [[ "$dir_count" -gt 0 ]]; then
  log "Scratch for sensor dataset already exists"
  exit "${E_SENSOR_DATASET_SCRATCH_EXISTS}"
fi

scratch="$(mktemp --directory --tmpdir="$TMPDIR" tmp_"$SENSOR"_"$DATASET".XXX)"

log "scratch directory: $scratch"

SENSOR_DATASET_TAR_PATH="$scratch/$SENSOR-$DATASET.tar"

tar c --directory="$RAW_DATA" --file="$SENSOR_DATASET_TAR_PATH" "${SENSOR}/${DATASET}"

# (Again) Fail if a final tar file for the sensor-dataset combo already exists

if [[ -f "${SENSOR_DATASET_FINAL_TAR_PATH}" ]]; then
  log "tar file for sensor dataset already exists, even though we checked earlier."
  exit "${E_SENSOR_DATASET_TAR_EXISTS}"
else
  log "Final tar file for sensor dataset does not exist. Move the file."
fi

mv "${SENSOR_DATASET_TAR_PATH}" "${SENSOR_DATASET_FINAL_TAR_PATH}"

SENSOR_DATASET_IRODS_TAR_PATH="${IRODS_COLLECTION}/${SENSOR}-${DATASET}.tar"

imkdir -p "${IRODS_COLLECTION}"

# Use ireg, NOT irsync
ireg -k -R terrarefRes "${SENSOR_DATASET_FINAL_TAR_PATH}" "${SENSOR_DATASET_IRODS_TAR_PATH}"

ichmod own rodsadmin "${SENSOR_DATASET_IRODS_TAR_PATH}"
imeta set -d "${SENSOR_DATASET_IRODS_TAR_PATH}" ipc_UUID "$(/var/lib/irods/iRODS/server/bin/cmd/generateuuid)"
isysmeta mod "${SENSOR_DATASET_IRODS_TAR_PATH}" datatype 'tar file'

# TODO: Grab and/or calculate hash and store in TSV file

echo -e "$(date +%Y_%m_%dT%H%M)\t${SENSOR_DATASET_FINAL_TAR_PATH}\t${SENSOR_DATASET_IRODS_TAR_PATH}" >> "${UPLOADED_TARS_FILE}"
