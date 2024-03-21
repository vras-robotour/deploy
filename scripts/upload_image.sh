#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

main() {
  echo
  echo "============= UPLOADING SINGULARITY IMAGE =============="
  echo

  local_exists=$(local_image_exists)
  remote_exists=$(remote_image_exists)

  if [ "$local_exists" == "true" ]; then
    echo "INFO: Found local image ${IMAGE_FILE}."
  else
    echo "ERROR: The local image ${IMAGE_FILE} does not exist."
    exit 1
  fi

  if [ "$remote_exists" == "true" ]; then
    echo "INFO: Found remote image ${IMAGE_FILE}."
    compare_versions_for_upload
  else
    echo "INFO: The remote image ${IMAGE_FILE} does not exist. Uploading a new one."
  fi

  upload_image
}

main