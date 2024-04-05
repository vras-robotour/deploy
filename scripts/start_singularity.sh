#!/usr/bin/env bash
set -eo pipefail  # Better error handling and exiting on error

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

print_usage() {
    cat <<EOF
Start RoboTour Singularity container. This script will do the following:

1. Check if the script is run inside a singularity container and exit if it is.
2. Check if singularity is installed and install it if it is not.
3. Update the deployment repository to the latest version.
4. Download the image if requested. (Use the -d or --download option)
5. Bind the necessary directories.
6. Set up the NVidia GPU support if requested. (Use the --nv option)
7. Export the necessary environment variables.
8. Start the singularity container using initialize_workspace.sh script.

Usage:
    start_singularity [<options>]

Options:
    -h|--help:  Print this help message.
    -d|--download:  Update the image before starting the container.
    -u|--username <username>:  Username as which to start the container.
    --nv:        Enable NVIDIA GPU support.
EOF
}

update_repository() {
    if is_online; then
        echo "INFO: Updating repository to the latest version."
        (cd "$PROJECT_PATH" && git pull)
    else
        echo "INFO: You do not seem to be online. Not updating the repository."
    fi
}

# If you have NVidia GPU and rendering acceleration doesn't work for you, call `export ARO_SINGULARITY_NV=1` before
# launching this script. However, this only works on Ubuntu 20.04 and older systems.
set_nvidia_gpu() {
    nv=""
    if [ "$ARO_SINGULARITY_NV" = "1" ]; then
        echo "INFO: Setting up NVidia GPU support."
        nv="--nv"
    else
        echo "INFO: Not setting up NVidia GPU support."
    fi
}

bind_directories() {
    bind="${ROBOTOUR_PATH}:${ROBOTOUR_PATH}"
    if [ -d /snap ]; then
      echo "INFO: Mounting /snap directory."
      bind="${bind},/snap:/snap"
    else
      echo "INFO: No /snap directory found. Skipping mounting."
    fi
}

export_environment_variable_if_present() {
    local var_name="$1"
    if [ -n "${!var_name}" ]; then
        export "SINGULARITYENV_$var_name"="${!var_name}"
    fi
}

main() {
    nvidia_gpu=""
    download_image=false
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -h|--help)
            print_usage
            ;;
            -d|--download)
            download_image=true
            shift # past argument
            ;;
            -u|--username)
            USERNAME="$2"
            shift # past argument
            shift # past value
            ;;
            --nv)
            nvidia_gpu="--nv"
            shift # past argument
            ;;
            *)
            print_usage
            handle_error "Unknown option: $1"
            shift # past argument or value
            ;;
        esac
    done

    echo
    echo "=========== STARTING SINGULARITY CONTAINER ============"
    echo

    # If in singularity container exit
    in_singularity && echo "ERROR: You are already inside a singularity container." && exit 1

    # Check whether singularity is installed and install it if not
    bash "${SCRIPTS_PATH}"/install_singularity.sh

    # Update the deployment repository
    update_repository

    # Download the image if requested
    $download_image && is_online && bash "${SCRIPTS_PATH}"/download_image.sh -u "$USERNAME"

    # Bind the necessary directories
    bind_directories


    # Export the necessary environment variables
    export SINGULARITYENV_PS1=$(echo -e "${PROMPT}")
    for var_name in "${CONTAINER_ENV_VARIABLES[@]}"; do
        export_environment_variable_if_present "$var_name"
    done

    echo "INFO: Starting Singularity container from image ${IMAGE_FILE}."
    singularity exec $nvidia_gpu -e -B "${bind}" "${IMAGES_PATH}/${IMAGE_FILE}" "${SCRIPTS_PATH}/initialize_workspace.sh" "$@"
}

# Execute main function
main "$@"
