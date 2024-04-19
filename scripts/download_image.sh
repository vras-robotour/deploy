#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

print_usage() {
    cat <<EOF
Download RoboTour Singularity image. The image will be downloaded from
the login3.rci.cvut.cz server. Please provide your username if it
differs from your current username.

The script will compare the versions of the local and remote images and
interactively walk you through the download process.

Usage:
    bash download_image.sh [<options>]

Options:
    -h|--help:  Print this help message.
    -u|--username <username>:  Username as which to download the image from the RCI server.
EOF
}

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

main() {
  echo
  echo "============ DOWNLOADING SINGULARITY IMAGE ============="
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
    info_log "Found the local image ${IMAGE_FILE}."
  else
    info_log "The local image does not exist."
  fi

  if [ "$remote_exists" == "true" ]; then
    info_log "Found the remote image ${IMAGE_FILE}."
    compare_versions_for_download
  else
    error_log "The remote image does not exist."
    exit 1
  fi

  download_image
}

main "$@"
