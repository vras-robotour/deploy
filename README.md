# RoboTour Singularity Deployment Scripts

This repository contains the deployment scripts for the Singularity container of the RoboTour project.

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


