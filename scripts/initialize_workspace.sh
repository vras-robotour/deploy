#!/bin/bash

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

init_workspace() {
  # Check if the catkin workspace is initialized
  if [ ! -e "${SRC_PATH}/CMakeLists.txt" ]; then
    echo "INFO: Initializing the catkin workspace."
    mkdir -p "${SRC_PATH}"
    cd "${WORKSPACE_PATH}" || exit 1
    source /opt/ros/noetic/setup.bash
    catkin_make -DPYTHON_EXECUTABLE=/usr/bin/python3
  else
    echo "INFO: The catkin workspace is already initialized."
  fi
}

update_packages() {
  for package in "${!PACKAGES[@]}"; do
    if [ ! -e "${SRC_PATH}/${package}/package.xml" ]; then
      echo "INFO: Cloning the package ${package}."
      git clone "${PACKAGES[$package]}" "${SRC_PATH}/${package}"
    else
      echo "INFO: Updating the package ${package} to the latest version."
      (cd "${SRC_PATH}/${package}" && git pull)
    fi
  done
}

start_bash() {
  echo "INFO: Starting interactive bash while sourcing the workspace."
  echo
  if [ $# -gt 0 ]; then
    exec bash -c "source \"${WORKSPACE_PATH}/devel/setup.bash\"; $*"
  else
    exec bash --init-file <(echo "source \"${WORKSPACE_PATH}/devel/setup.bash\"")
  fi
}

main() {
  # Check if the singularity container is running
  if [ "$SINGULARITY_NAME" != "${IMAGE_FILE}" ]; then
    echo "ERROR: You are not inside the ARO singularity container."
    echo "       Please start the singularity first using start_singularity_aro."
    exit 1
  fi

  # Check if the workspace exists
  if [ ! -d "${WORKSPACE_PATH}" ]; then
    echo "INFO: Creating workspace in ${WORKSPACE_PATH}."
    mkdir -p "${WORKSPACE_PATH}"
  fi

  # Initialize the workspace
  init_workspace

  # Update the student packages
  echo
  echo "================== UPDATING PACKAGES =================="
  echo

  update_packages

  echo
  echo "======================================================="
  echo

  # Start the interactive bash
  start_bash "$@"
}

main "$@"
