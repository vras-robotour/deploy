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
    info_log "Initializing the catkin workspace."
    source /opt/ros/noetic/setup.bash
    rosdep update
    rosdep install --from-paths src --ignore-src -r -y
    catkin build -DPYTHON_EXECUTABLE=/usr/bin/python3
  else
    info_log "The catkin workspace is already initialized."
  fi
}

update_packages() {
  if ! is_online; then
    info_log "You do not seem to be online. Not updating the packages."
    return
  fi

  for package in "${!PACKAGES[@]}"; do
    if [ ! -e "${SRC_PATH}/${package}/package.xml" ]; then
      info_log "Cloning the package \e[1;95m${package}\e[0m."
      git clone "${PACKAGES[$package]}" "${SRC_PATH}/${package}"
    else
      info_log "Updating the package \e[1;95m${package}\e[0m to the latest version."
      (cd "${SRC_PATH}/${package}" && git pull)
    fi
  done
}

start_bash() {
  cd "${WORKSPACE_PATH}" || exit 1
  info_log "Starting interactive bash while sourcing the workspace."
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
    error_log "You are not inside the singularity container."
    echo "       Please start the singularity first using start_singularity.sh."
    exit 1
  fi

  # Check if the workspace exists
  if [ ! -d "${WORKSPACE_PATH}" ]; then
    info_log "Creating workspace in ${WORKSPACE_PATH}."
    mkdir -p "${WORKSPACE_PATH}"
  fi

  if [ ! -d "${SRC_PATH}" ]; then
    info_log "Creating source directory in ${SRC_PATH}."
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

  # Configure tmux to start with bash by default if there is no user configuration
  if [ ! -f "$HOME"/.tmux.conf ]; then
    echo "set-option -g default-shell /bin/bash" > "$HOME"/.tmux.conf
  fi

  # Start the interactive bash
  start_bash "$@"
}

main "$@"
