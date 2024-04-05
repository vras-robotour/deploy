#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

print_usage() {
    cat <<EOF
Build RoboTour Singularity image. The image will be built based on the
definition file in the build directory.

Usage:
    bash build_image.sh [<options>]

Options:
    -h|--help:  Print this help message.
EOF
}

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

main() {
  echo
  echo "============= BUILDING SINGULARITY IMAGE =============="
  echo

  # Parse arguments
  while [[ $# -gt 0 ]]; do
      key="$1"
      case $key in
          -h|--help)
          print_usage
          ;;
          *)
          print_usage
          handle_error "Unknown option: $1"
          shift # past argument or value
          ;;
      esac
  done

  cd "${BUILD_PATH}" || exit 1

  # Ask user if he is sure about removing the old image.
  if [ -e "${IMAGES_PATH}/${IMAGE_FILE}" ]; then
      read -p "This will remove the old image ${IMAGE_FILE}. Do you want to create backup? [y/N] "
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
          sudo rm -f "${IMAGES_PATH}/${IMAGE_FILE}"
      else
          sudo mv "${IMAGES_PATH}/${IMAGE_FILE}" "${IMAGES_PATH}/${IMAGE_FILE}.bak"
      fi
  fi

  # Build the image.
  sudo singularity build --nv "${IMAGES_PATH}/${IMAGE_FILE}" "${DEFINITION_FILE}" 2>&1 | tee "${LOG_FILE}"

  # Change the owner of the image to the current user.
  if [ -e "${IMAGES_PATH}/${IMAGE_FILE}" ]; then
      sudo chown "$(id -un)":"$(id -gn)" "${IMAGES_PATH}/${IMAGE_FILE}" || true
  fi
}

main "$@"
