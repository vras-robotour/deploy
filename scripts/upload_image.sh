#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

main() {
  echo
  echo "============= UPLOADING SINGULARITY IMAGE =============="
  echo

  # Parse arguments
  while [[ $# -gt 0 ]]; do
      key="$1"
      case $key in
          -h|--help)
          print_usage
          ;;
          -u|--username)
          USERNAME="$2"
          shift # past argument
          shift # past value
          ;;
          *)
          print_usage
          handle_error "Unknown option: $1"
          shift # past argument or value
          ;;
      esac
  done

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

main "$@"
