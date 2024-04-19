#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

print_usage() {
    cat <<EOF
Installs Singularity on the system. The script will install Singularity CE
from the PPA repository.

Usage:
    bash install_singularity.sh [<options>]

Options:
    -h|--help:  Print this help message.
EOF
}

source "$(realpath "$(dirname "${BASH_SOURCE[0]}")")/utils.sh"

check_singularity() {
    if [ -n "${SINGULARITY_NAME:-}" ]; then
        error_log "Cannot run install_singularity from inside Singularity."
        exit 1
    fi
}

# Check if Singularity is already installed
check_installed_singularity() {
    if which singularity >/dev/null; then
        info_log "Singularity is already installed."
        exit 0
    fi
}

# Check if Singularity CE or Apptainer is already installed via dpkg-query
check_installed_via_dpkg() {
    if ! which dpkg-query >/dev/null; then
        error_log "Cannot automatically install Singularity on this system (only Ubuntu is supported).\n\
        Follow the official install guide at https://apptainer.org/admin-docs/master/installation.html ,\n\
        or you can try directly installing from the Apptainer releases page: https://github.com/apptainer/apptainer/releases."
        exit 1
    fi

    if [[ "$(dpkg-query --show --showformat='${db:Status-Status}\n' singularity-ce)" == "installed" ]] || [[ "$(dpkg-query --show --showformat='${db:Status-Status}\n' apptainer)" == "installed" ]]; then
        info_log "Singularity is already installed."
        exit 0
    fi
}

# Install Singularity via PPA
install_singularity_via_ppa() {
    echo "Installing Singularity. Be prepared to type your sudo password and press [Enter] for adding the PPA."
    if (sudo add-apt-repository ppa:peci1/singularity-ce-v3 && sudo apt install singularity-ce); then
        info_log "Singularity installed successfully."
    else
        error_log "Install failed.\n\
        Cannot automatically install Singularity on this system (only Ubuntu is supported).\n\
        Follow the official install guide at https://apptainer.org/admin-docs/master/installation.html ,\n\
        or you can try directly installing from the Apptainer releases page: https://github.com/apptainer/apptainer/releases."
        exit 1
    fi
}

# Main function to execute all necessary steps
main() {
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

    check_singularity
    check_installed_singularity
    check_installed_via_dpkg
    install_singularity_via_ppa
}

# Execute main function
main "$@"
