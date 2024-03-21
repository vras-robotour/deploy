#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

main() {
  echo
  echo "============ DOWNLOADING SINGULARITY IMAGE ============="
  echo
  local_exists=$(local_image_exists)
  remote_exists=$(remote_image_exists)

  if [ "$local_exists" == "true" ]; then
    echo "INFO: Found the local image ${IMAGE_FILE}."
  else
    echo "INFO: The local image does not exist."
  fi

  if [ "$remote_exists" == "true" ]; then
    echo "INFO: Found the remote image ${IMAGE_FILE}."
    compare_versions_for_download
  else
    echo "ERROR: The remote image does not exist."
    exit 1
  fi


  download_image
}

main