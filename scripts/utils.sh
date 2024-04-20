# ============= START: LOGGING =============

info_log() {
	echo -e "\e[34m[INFO]\e[0m $1"
}

warn_log() {
	echo -e "\e[33m[WARNING]\e[0m $1"
}

error_log() {
	echo -e "\e[31m[ERROR]\e[0m $1"
}

read_input() {
	echo -en "\e[32m[INPUT]\e[0m $1"
	read -r REPLY
}

# ============= START: END =============

# ============= START: HELPER FUNCTIONS FOR VARIABLES =============

local_arch() {
	local arch="amd64"
	if [ -d "/usr/lib/aarch64-linux-gnu/tegra" ]; then
		arch="jetson"
	elif [[ "$(uname -m)" = *"aarch"* ]] || [[ "$(uname -m)" = *"arm"* ]]; then
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

	error_log "RoboTour deploy directory not found."
	return 1
}

check_ssh_key_or_prompt_password() {
	local max_attempts=3
	local attempt=0

	# Check if SSH key exists for the server
	if ssh -o BatchMode=yes ${USERNAME}@${REMOTE_SERVER} true 2>/dev/null; then
		# If SSH key exists and connection is successful, set ssh_key_exists flag
		info_log "Connection to \e[1;95m${REMOTE_SERVER}\e[0m successful."
		return 0
	fi

	while [ $attempt -lt $max_attempts ]; do
		attempt=$((attempt + 1))
		if [ $attempt -eq 1 ]; then
			warn_log "No SSH key found for \e[1;95m${REMOTE_SERVER}\e[0m. Please enter the password."
		else
			warn_log "Incorrect password. Please try again. (Attempt $attempt/$max_attempts)"
		fi

		read -rsp "Password: " SSH_PASSWORD
		echo

		# Attempt to connect using the provided password
		if sshpass -p "${SSH_PASSWORD}" ssh ${USERNAME}@${REMOTE_SERVER} true 2>/dev/null; then
			export SSH_PASSWORD
			return 0
		fi
	done

	error_log "Maximum number of attempts exceeded. Exiting."
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
ARCH=$(local_arch) # amd64, jetson, arm64

IMAGE_FILE="${BASE_NAME}_${ARCH}.simg"
LOG_FILE="${LOGS_PATH}/${BASE_NAME}.log"
SETUP_FILE="${WORKSPACE_PATH}/devel/setup.bash"

if [ "$ARCH" = "jetson" ]; then
	DEFINITION_FILE="${BUILD_PATH}/jetson.def"
else
	DEFINITION_FILE="${BUILD_PATH}/desktop.def"
fi

# Remote server
USERNAME="${USERNAME:-$(whoami)}"
REMOTE_IMAGES_PATH="/mnt/data/vras/data/robotour2024/images"
#REMOTE_IMAGES_PATH="/data/robotour2024/images"
REMOTE_SERVER="login3.rci.cvut.cz"
#REMOTE_SERVER="subtdata.felk.cvut.cz"
SSH_PASSWORD=""

# Environment variables to be passed to the container
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

PACKAGES["cloud_proc"]="https://github.com/ctu-vras/cloud_proc.git"
PACKAGES["map_data"]="https://github.com/vras-robotour/map_data.git"
PACKAGES["naex"]="https://github.com/vras-robotour/naex.git"
PACKAGES["osm2qr"]="https://github.com/vras-robotour/osm2qr.git"
PACKAGES["robotour"]="https://github.com/vras-robotour/robotour.git"
PACKAGES["image_segmentation"]="https://github.com/vras-robotour/image_segmentation.git"

# ============= END: VARIABLES =============

# ============= START: UTILITY FUNCTIONS =============

handle_error() {
	error_log "$1"
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
		[ "$?" = "126" ] && return 1 # Operation not permitted; this happens inside Singularity. In that case, succeed.
		return 0
	else
		return 0
	fi
}

in_singularity() {
	[ -n "$SINGULARITY_CONTAINER" ]
}

get_remote_image_version() {
	if [ -n "$SSH_PASSWORD" ]; then
		remote_version=$(sshpass -p "${SSH_PASSWORD}" ssh -t ${USERNAME}@${REMOTE_SERVER} \
			"cd ${REMOTE_IMAGES_PATH}; \
            singularity inspect ${IMAGE_FILE}" 2>/dev/null |
			grep "Version:" | cut -d ':' -f 2 | tr -d '[:space:]')
	else
		remote_version=$(ssh -t ${USERNAME}@${REMOTE_SERVER} \
			"cd ${REMOTE_IMAGES_PATH}; \
            singularity inspect ${IMAGE_FILE}" 2>/dev/null |
			grep "Version:" | cut -d ':' -f 2 | tr -d '[:space:]')
	fi
	echo "${remote_version}"
}

get_local_image_version() {
	local_version=$(singularity inspect "${IMAGES_PATH}/${IMAGE_FILE}" 2>/dev/null |
		grep "Version:" | cut -d ':' -f 2 | tr -d '[:space:]')
	echo "${local_version}"
}

compare_versions_for_upload() {
	local_version=$(get_local_image_version)
	remote_version=$(get_remote_image_version)

	echo
	if [[ "$local_version" == "$remote_version" ]]; then
		# Versions are equal
		read_input "The remote image is already up to date (${local_version}). Do you want to continue? [y/N] "
	elif [[ "$(echo -e "$local_version\n$remote_version" | sort -V | tail -n1)" == "$local_version" ]]; then
		# Local version is strictly newer
		read_input "The local image is newer (${local_version}) than the remote one (${remote_version}). Do you want to continue? [y/N] "
	else
		# Remote version is strictly newer
		read_input "The remote image (${remote_version}) is newer than the local one (${local_version}). Do you want to continue? [y/N] "
	fi

	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo
		info_log "Aborting the upload."
		exit 0
	fi
}

compare_versions_for_download() {
	local_version=$(get_local_image_version)
	remote_version=$(get_remote_image_version)

	if [[ "$local_version" == "$remote_version" ]]; then
		# Versions are equal
		read_input "The local image is already up to date (${local_version}). Do you want to continue? [y/N] "
	elif [[ "$(echo -e "$local_version\n$remote_version" | sort -V | tail -n1)" == "$local_version" ]]; then
		# Local version is strictly newer
		read_input "The local image is newer (${local_version}) than the remote one (${remote_version}). Do you want to continue? [y/N] "
	else
		# Remote version is strictly newer
		read_input "The remote image (${remote_version}) is newer than the local one (${local_version}). Do you want to continue? [y/N] "
	fi

	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo
		info_log "Aborting the download."
		exit 0
	fi
}

remote_image_exists() {
	if [ -n "$SSH_PASSWORD" ]; then
		exists=$(sshpass -p "${SSH_PASSWORD}" ssh -t ${USERNAME}@${REMOTE_SERVER} \
			"test -f ${REMOTE_IMAGES_PATH}/${IMAGE_FILE} && echo true || echo false" 2>/dev/null)
	else
		exists=$(ssh -t ${USERNAME}@${REMOTE_SERVER} \
			"test -f ${REMOTE_IMAGES_PATH}/${IMAGE_FILE} && echo true || echo false" 2>/dev/null)
	fi
	echo "${exists}" | grep -q "true" && echo "true" || echo "false"
}

local_image_exists() {
	if [ -f "${IMAGES_PATH}/${IMAGE_FILE}" ]; then
		echo "true"
	else
		echo "false"
	fi
}

upload_image() {
	if [ -n "$SSH_PASSWORD" ]; then
		rsync -P --rsh="sshpass -p ${SSH_PASSWORD} ssh -l ${USERNAME}" "${IMAGES_PATH}/${IMAGE_FILE}" "${REMOTE_SERVER}:${REMOTE_IMAGES_PATH}/${IMAGE_FILE}"
	else
		rsync -P "${IMAGES_PATH}/${IMAGE_FILE}" "${USERNAME}@${REMOTE_SERVER}:${REMOTE_IMAGES_PATH}/${IMAGE_FILE}"
	fi
}

download_image() {
	if [ -n "$SSH_PASSWORD" ]; then
		rsync -P --rsh="sshpass -p ${SSH_PASSWORD} ssh -l ${USERNAME}" "${REMOTE_SERVER}:${REMOTE_IMAGES_PATH}/${IMAGE_FILE}" "${IMAGES_PATH}/${IMAGE_FILE}"
	else
		rsync -P "${USERNAME}@${REMOTE_SERVER}:${REMOTE_IMAGES_PATH}/${IMAGE_FILE}" "${IMAGES_PATH}/${IMAGE_FILE}"
	fi
}

# ============= END: UTILITY FUNCTIONS =============
