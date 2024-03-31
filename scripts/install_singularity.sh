#!/usr/bin/env bash
set -euo pipefail  # Better error handling and exiting on error

check_singularity() {
    if [ -n "${SINGULARITY_NAME:-}" ]; then
        echo "ERROR: Cannot run install_singularity from inside Singularity."
        exit 1
    fi
}

# Check if Singularity is already installed
check_installed_singularity() {
    if which singularity >/dev/null; then
        echo "INFO: Singularity is already installed."
        exit 0
    fi
}

# Check if Singularity CE or Apptainer is already installed via dpkg-query
check_installed_via_dpkg() {
    if ! which dpkg-query >/dev/null; then
        echo -e "ERROR: Cannot automatically install Singularity on this system (only Ubuntu is supported).\n\
        Follow the official install guide at https://apptainer.org/admin-docs/master/installation.html ,\n\
        or you can try directly installing from the Apptainer releases page: https://github.com/apptainer/apptainer/releases."
        exit 1
    fi

    if [[ "$(dpkg-query --show --showformat='${db:Status-Status}\n' singularity-ce)" == "installed" ]] || [[ "$(dpkg-query --show --showformat='${db:Status-Status}\n' apptainer)" == "installed" ]]; then
        echo "INFO: Singularity is already installed."
        exit 0
    fi
}

# Install Singularity via PPA
install_singularity_via_ppa() {
    echo "Installing Singularity. Be prepared to type your sudo password and press [Enter] for adding the PPA."
    if (sudo add-apt-repository ppa:peci1/singularity-ce-v3 && sudo apt install singularity-ce); then
        echo "INFO: Singularity installed successfully."
    else
        echo -e "ERROR: Install failed.\n\
        Cannot automatically install Singularity on this system (only Ubuntu is supported).\n\
        Follow the official install guide at https://apptainer.org/admin-docs/master/installation.html ,\n\
        or you can try directly installing from the Apptainer releases page: https://github.com/apptainer/apptainer/releases."
        exit 1
    fi
}

# Main function to execute all necessary steps
main() {
    check_singularity
    check_installed_singularity
    check_installed_via_dpkg
    install_singularity_via_ppa
}

# Execute main function
main
