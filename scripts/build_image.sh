#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

main() {
  echo
  echo "============= BUILDING SINGULARITY IMAGE =============="
  echo

  cd "${BUILD_PATH}" || exit 1

  # Ask user if he is sure about removing the old image.
  if [ -e "${IMAGES_PATH}/${IMAGE_FILE}" ]; then
      read -p "This will remove the old image ${IMAGE_FILE}. Do you want to create backup? [y/N] " -n 1 -r
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

main
