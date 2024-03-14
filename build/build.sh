#!/bin/bash -e

NAME="robotour"

IMAGE_FILE="../images/${NAME}.simg"
DEF_FILE="${NAME}.def"
LOG_FILE="${NAME}.log"

# Get the directory of this script (even when it is called from another directory).
BUILD_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BUILD_DIR}"

# Ask user if he is sure about removing the old image.
if [ -e "${IMAGE_FILE}" ]; then
    read -p "This will remove the old image ${IMAGE_FILE}. Are you sure? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit
    fi
fi

# Build the image.
sudo rm -f "${IMAGE_FILE}"
sudo singularity build "${IMAGE_FILE}" "${DEF_FILE}" 2>&1 | tee "${LOG_FILE}"

# Change the owner of the image to the current user.
if [ -e "${IMAGE_FILE}" ]; then
    sudo chown "$(id -un)":"$(id -gn)" "${IMAGE_FILE}" || true
fi
