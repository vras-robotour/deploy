#!/bin/bash

print_usage() {
    cat <<EOF
Initialize the catkin workspace for the RoboTour project. This script should
not be run directly. Instead, use the start_singularity.sh script to start the
singularity container and then run this script inside the container.
EOF
}

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

init_workspace() {
  # Check if the catkin workspace is initialized
  cd "${WORKSPACE_PATH}" || exit 1
  if [ ! -d build ] || [ ! -d devel ]; then
    echo "INFO: Initializing the catkin workspace."
    source /opt/ros/noetic/setup.bash
    rosdep update
    rosdep install --from-paths src --ignore-src -r -y
    catkin build -DPYTHON_EXECUTABLE=/usr/bin/python3
  else
    echo "INFO: The catkin workspace is already initialized."
  fi
}

update_packages() {
  if ! is_online; then
    echo "INFO: You do not seem to be online. Not updating the packages."
    return
  fi

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
  cd "${WORKSPACE_PATH}" || exit 1
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
    echo "ERROR: You are not inside the singularity container."
    echo "       Please start the singularity first using start_singularity.sh."
    exit 1
  fi

  # Check if the workspace exists
  if [ ! -d "${WORKSPACE_PATH}" ]; then
    echo "INFO: Creating workspace in ${WORKSPACE_PATH}."
    mkdir -p "${WORKSPACE_PATH}"
  fi

  if [ ! -d "${SRC_PATH}" ]; then
    echo "INFO: Creating source directory in ${SRC_PATH}."
    mkdir -p "${SRC_PATH}"
  fi

  # Update the student packages
  echo
  echo "================== UPDATING PACKAGES =================="
  echo

  update_packages

  echo
  echo "======================================================="
  echo

  # Initialize the workspace
  init_workspace

  # Start the interactive bash
  start_bash "$@"
}

main "$@"
