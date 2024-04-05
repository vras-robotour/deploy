# RoboTour Singularity Deployment Scripts

This repository contains the deployment scripts for the Singularity container of the RoboTour project. The documentation contains following sections:

- [Repository structure](#repository-structure)
- [How to use](#how-to-use)
- [Commands in container](#commands-in-container)

## Repository structure

The repository contains the following directories and files:

```
├── build
│   ├── packages.apt
│   ├── packages.pip
│   ├── robotour.def
│   └── ...
├── commands
│   ├── build_workspace
│   ├── clion
│   ├── pycharm
│   ├── source_noetic
│   ├── source_workspace
│   └── ...
├── images
├── logs
└── scripts
    ├── build_image.sh
    ├── download_image.sh
    ├── start_singularity.sh
    ├── upload_image.sh
    └── ...
```

- `build` - contains the Singularity definition files for building the container and the apt file with the dependencies. If you want to add new dependencies, you have to add them to the `packages.apt` or `packages.pip` file.
- `commands` - contains the scripts that are used in the container. The scripts are used to build the workspace, start the IDEs, and source the workspace.
- `images` - contains the built or downloaded Singularity images.
- `logs` - contains the logs from building the container.
- `scripts` - contains the scripts for building, downloading, starting, and uploading the Singularity container. Each script has a `help` option that shows the usage of the script. You can run the script with the `help` option by running the script with the `-h` or `--help` option.

## How to use

### Using the container

To use the container, first you have to download it. You can do it by running the following command:

```bash
bash scripts/download_image.sh
```

This will download the singularity image to the `images` directory.

Then, you can run the container by running the following command:

```bash
bash scripts/start_singularity.sh
```

This will start the container, and you will be able to use the RoboTour project.

### Building the container

If you want to build the container, you can do it by running the following command:

```bash
bash scripts/build_image.sh
```

This will build the singularity image and save it to the `images` directory. Next you have to upload it to the server.

```bash
bash scripts/upload_image.sh
```

## Commands in container

The container contains the following commands:

- `build_workspace` - builds the workspace
- `clion` - starts the CLion IDE
- `pycharm` - starts the PyCharm IDE
- `source_noetic` - sources the ROS Noetic workspace
- `source_workspace` - sources the RoboTour workspace
