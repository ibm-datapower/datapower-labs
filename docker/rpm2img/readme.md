## rpm2img Purpose:

Given the DataPower Gateway RPM files, create a Docker Image suitable
for further DataPower work.

## Usage:

Prerequisites:
Meet the documented DataPower Gateway Virtual Edition minimum requirements.
Four cores and 8 GB RAM is a good starting place.
Have Docker already installed and working properly.
A browser must be available for accepting the license.
The best experience is with Firefox available on the build host.
This example is Makefile based; GNU make is required.
This example requires schroot; [EPEL](https://fedoraproject.org/wiki/EPEL) is strongly suggested.

1. Download the DataPower Gateway Virtual Edition RPM files from
IBM PassPort Advantage (PPA).

2. For all image versions, rename the files "ibm-datapower-common.rpm" and "ibm-datapower-image.rpm"
respectively. Then place the image files and the Dockerfile in a directory such as `~/datapower-docker/`

3. Run `docker build -t ibm-datapower-factory .`
(notice the trailing dot is part of the command)

4. Create a Docker container with the name `datapower`, run it with elevated privileges, and open port 9090 when you enter the following command: `docker run -d --name datapower --privileged -p 9090:9090 ibm-datapower-factory`.

5. To accept the license and perform initialization, log in to https://Docker_IP:9090, with password:admin and username:admin.

6. Try out your new "base image"
  * `make run` -- Run a container from the base image, named "datapower" by default
  * `make cli` -- Access the cli of the running "datapower" container
  * `make gui` -- Access the DataPower WebGUI
  * `make rm`  -- Stop and remove the container "datapower"
  * Use it as the FROM in another Docker project!

The Makefile itself contains extensive, detailed notes.

This is the first step in taking advantage of a Dockerized
DataPower Gateway.  The next step is to create another image based upon
this image.
