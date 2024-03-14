# RoboTour Singularity Deployment Scripts

This repository contains the deployment scripts for the Singularity container of the RoboTour project.

## Repository Structure

The repository is structured as follows:

    deploy/
    ├── build
    │   ├── build.sh
    │   ├── robotour.def
    │   └── ...
    ├── config
    │   ├── packages.apt
    │   ├── robolab_noetic.rosinstall
    │   └── ...
    ├── images
    │   └── robotour.simg
    ├── README.md
    └── scripts
        ├── build
        │   ├── install_editors
        │   ├── setup_catkin_workspace
        │   └── setup_noetic_workspaces
        ├── singularity
        │   ├── download_image
        │   ├── initialize_workspace
        │   ├── install
        │   └── start
        └── utils.sh
