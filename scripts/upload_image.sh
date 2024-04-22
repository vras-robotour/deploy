#!/bin/bash
set -euo pipefail  # Better error handling and exiting on error

print_usage() {
    cat <<EOF
Upload RoboTour Singularity image. The image will be uploaded to the login3.rci.cvut.cz server.
Please provide your username if it differs from your current username.

The script will compare the versions of the local and remote images and
interactively walk you through the upload process.

Usage:
    bash upload_image.sh [<options>]

Options:
    -h|--help:  Print this help message.
    -u|--username <username>:  Username as which to upload the image to the RCI server.
EOF
}

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

  check_ssh_key_or_prompt_password

  local_exists=$(local_image_exists)
  remote_exists=$(remote_image_exists)

  if [ "$local_exists" == "true" ]; then
    info_log "Found local image \e[1;95m${IMAGE_FILE}\e[0m."
  else
    error_log "The local image \e[1;95m${IMAGE_FILE}\e[0m does not exist."
    exit 1
  fi

  if [ "$remote_exists" == "true" ]; then
    info_log "Found remote image \e[1;95m${IMAGE_FILE}\e[0m."
    compare_versions_for_upload
  else
    info_log "The remote image \e[1;95m${IMAGE_FILE}\e[0m does not exist. Uploading a new one."
  fi

  upload_image
}

main "$@"
