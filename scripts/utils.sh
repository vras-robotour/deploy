# ============= START: HELPER FUNCTIONS FOR VARIABLES =============

local_arch() {
    local arch="amd64"
    if [[ "$(uname -m)" = *"aarch"* ]] || [[ "$(uname -m)" = *"arm"* ]]; then
        arch="arm64"
    fi
    echo "$arch"
}

get_project_path() {
  script_path="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

  while [[ "$script_path" != "/" ]]; do
    if [[ -d "$script_path/deploy" ]]; then
      echo "$script_path/deploy"
      return 0
    fi
    script_path="$(dirname "$script_path")"
  done

  echo "RoboTour deploy directory not found."
  return 1
}

# ============= END: HELPER FUNCTIONS FOR VARIABLES =============

# ============= START: VARIABLES =============

# Paths
PROJECT_PATH=$(get_project_path)

LOGS_PATH=$(realpath "$PROJECT_PATH/logs")
BUILD_PATH=$(realpath "$PROJECT_PATH/build")
CONFIG_PATH=$(realpath "$PROJECT_PATH/config")
IMAGES_PATH=$(realpath "$PROJECT_PATH/images")
SCRIPTS_PATH=$(realpath "$PROJECT_PATH/scripts")
COMMANDS_PATH=$(realpath "$PROJECT_PATH/commands")

ROBOTOUR_PATH=$(realpath "$PROJECT_PATH/..")

WORKSPACE_PATH="${ROBOTOUR_PATH}/workspace"
SRC_PATH="${WORKSPACE_PATH}/src"

# Important files
BASE_NAME="robotour"
ARCH=$(local_arch)

IMAGE_FILE="${BASE_NAME}_${ARCH}.simg"
DEFINITION_FILE="${BUILD_PATH}/${BASE_NAME}.def"
LOG_FILE="${LOGS_PATH}/${BASE_NAME}.log"
SETUP_FILE="${WORKSPACE_PATH}/devel/setup.bash"

# Remote server
USERNAME="kuceral4"
REMOTE_IMAGES_PATH="/mnt/personal/kuceral4/robotour/images"
REMOTE_SERVER="login3.rci.cvut.cz"

# Environment variables to be passed to the container
PROMPT='\[\033[01;32m\]\u@\h\[\033[01;33m\] [RoboTour] \[\033[01;34m\]\w\[\033[01;33m\]$(parse_git_branch) \[\033[01;34m\]\$\[\033[00m\] '
CONTAINER_ENV_VARIABLES=(
    ROS_MASTER_URI
    ROS_HOSTNAME
    ROS_IP
    ROS_HOME
    ROS_LOG_DIR
    ROSCONSOLE_CONFIG_FILE
    ROS_PYTHON_LOG_CONFIG_FILE
    HOSTNAME
    DISPLAY
    USER
    XAUTHORITY
    LANG
    DBUS_SESSION_BUS_ADDRESS
    SETUP_FILE
    WORKSPACE_PATH
)

# Packages

declare -A PACKAGES

PACKAGES["test_package"]="https://github.com/vras-robotour/test_package.git"
PACKAGES["naex"]="https://github.com/vras-robotour/naex.git"
PACKAGES["map_data"]="https://github.com/vras-robotour/map_data.git"

# ============= END: VARIABLES =============

# ============= START: UTILITY FUNCTIONS =============

handle_error() {
    echo "ERROR: $1" >&2
    exit 1
}

is_online() {
	local url="https://www.cvut.cz/sites/default/files/favicon.ico"
	local domain="cvut.cz"
	if which wget >/dev/null; then
		timeout 1 wget --spider -q -O /dev/null "$url" && return 0 || return 1
	elif which curl >/dev/null; then
		timeout 1 curl -sfI -o /dev/null "$url" && echo 1 || echo 0
	elif which ping; then
		timeout 1 ping -c1 "$domain" 2>/dev/null 1>/dev/null
		[ "$?" = "0" ] && return 1
		[ "$?" = "126" ] && return 1  # Operation not permitted; this happens inside Singularity. In that case, succeed.
		return 0
	else
		return 0
	fi
}

in_singularity() {
  [ -n "$SINGULARITY_CONTAINER" ]
}



get_remote_image_version() {
    remote_version=$(ssh -t ${USERNAME}@${REMOTE_SERVER} \
        "cd ${REMOTE_IMAGES_PATH}; \
        singularity inspect ${IMAGE_FILE}" 2>/dev/null | \
        grep "Version:" | cut -d ':' -f 2 | tr -d '[:space:]')
    echo "${remote_version}"
}

get_local_image_version() {
    local_version=$(singularity inspect "${IMAGES_PATH}/${IMAGE_FILE}" 2>/dev/null | \
        grep "Version:" | cut -d ':' -f 2 | tr -d '[:space:]')
    echo "${local_version}"
}

compare_versions_for_upload() {
    local_version=$(get_local_image_version)
    remote_version=$(get_remote_image_version)

    if [[ "$local_version" == "$remote_version" ]]; then
        # Versions are equal
        read -p "INPUT: The remote image is already up to date (${local_version}). Do you want to continue? [y/N] " -n 1 -r
    elif [[ "$(echo -e "$local_version\n$remote_version" | sort -V | tail -n1)" == "$local_version" ]]; then
        # Local version is strictly newer
        read -p "INPUT: This upload will overwrite the old remote image (${remote_version}) with newer
local image (${local_version}). Are you sure you want to continue? [y/N] " -n 1 -r
    else
        # Remote version is strictly newer
        read -p "INPUT: The remote image (${remote_version}) is newer than the local one (${local_version}). Do you want to continue? [y/N] " -n 1 -r
    fi

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo
        echo "INFO: Aborting the upload."
        exit 0
    fi
}

compare_versions_for_download() {
  local_version=$(get_local_image_version)
  remote_version=$(get_remote_image_version)

  if [[ "$local_version" == "$remote_version" ]]; then
      # Versions are equal
      read -p "INPUT: The local image is already up to date (${local_version}). Do you want to continue? [y/N] " -n 1 -r
  elif [[ "$(echo -e "$local_version\n$remote_version" | sort -V | tail -n1)" == "$local_version" ]]; then
      # Local version is strictly newer
      read -p "INPUT: The local image is newer (${local_version}) than the remote one (${remote_version}). Do you want to continue? [y/N] " -n 1 -r
  else
      # Remote version is strictly newer
      read -p "INPUT: This download will overwrite the old local image (${local_version}) with newer
remote image (${remote_version}). Are you sure you want to continue? [y/N] " -n 1 -r
  fi

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo
      echo "INFO: Aborting the download."
      exit 0
  fi
}

remote_image_exists() {
  exists=$(ssh -t ${USERNAME}@${REMOTE_SERVER} \
    "test -f ${REMOTE_IMAGES_PATH}/${IMAGE_FILE} && echo true || echo false" 2>/dev/null)
  echo "${exists}" | tr -d '[:space:]'
}


local_image_exists() {
  if [ -f "${IMAGES_PATH}/${IMAGE_FILE}" ]; then
    echo "true"
  else
    echo "false"
  fi
}

upload_image() {
  scp "${IMAGES_PATH}/${IMAGE_FILE}" "${USERNAME}@${REMOTE_SERVER}:${REMOTE_IMAGES_PATH}/"
}

download_image() {
  scp "${USERNAME}@${REMOTE_SERVER}:${REMOTE_IMAGES_PATH}/" "${IMAGES_PATH}/${IMAGE_FILE}"
}

# ============= END: UTILITY FUNCTIONS =============
