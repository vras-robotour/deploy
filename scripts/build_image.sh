#!/bin/bash
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

create_metadata() {
    created_at=$(date +"%Y-%m-%d %H:%M:%S")
    created_by=$(git config --get user.name)

    echo "{
    \"created_at\": \"${created_at}\",
    \"created_by\": \"${created_by}\"
}" > "${IMAGES_PATH}/${METADATA_FILE}"
}

remove_image_or_create_backup() {
    read -rp "This will remove the old image ${IMAGE_FILE}. Do you want to create backup? [y/N] "
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        sudo rm -f "${IMAGES_PATH}/${IMAGE_FILE}"
        sudo rm -f "${IMAGES_PATH}/${METADATA_FILE}"
    else
        sudo mv "${IMAGES_PATH}/${IMAGE_FILE}" "${IMAGES_PATH}/${IMAGE_FILE}.bak"
        sudo mv "${IMAGES_PATH}/${METADATA_FILE}" "${IMAGES_PATH}/${METADATA_FILE}.bak"
    fi
}

build_image() {
  if [ "${ARCH}" = "jetson" ]; then
      export SINGULARITY_TMPDIR=/home/robot/robotour2024/tmp
      export SINGULARITY_CACHEDIR=/home/robot/robotour2024/cache
      sudo -E singularity build --nv "${IMAGES_PATH}/${IMAGE_FILE}" "${DEFINITION_FILE}" 2>&1 | tee "${LOG_FILE}"
  else
      sudo singularity build --nv "${IMAGES_PATH}/${IMAGE_FILE}" "${DEFINITION_FILE}" 2>&1 | tee "${LOG_FILE}"
  fi
}

change_owner_and_rights() {
  sudo chown "${USER}":"${USER}" "${IMAGES_PATH}/${IMAGE_FILE}"
  sudo chown "${USER}":"${USER}" "${IMAGES_PATH}/${METADATA_FILE}"
  sudo chmod 775 "${IMAGES_PATH}/${IMAGE_FILE}"
  sudo chmod 664 "${IMAGES_PATH}/${METADATA_FILE}"
}

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

  if [ -e "${IMAGES_PATH}/${IMAGE_FILE}" ]; then
      remove_image_or_create_backup
  fi

  build_image
  create_metadata
  change_owner_and_rights
}

main "$@"
