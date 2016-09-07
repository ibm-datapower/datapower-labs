## deb2img Purpose:

Given the DataPower Gateway Debian files, create a Docker Image suitable
for further DataPower work.

NOTICE: This is a legacy example that does not take advantage of DataPower Gateway for Docker. Consider using the [ibmcom-datapower-example](https://github.com/ibm-datapower/datapower-labs/tree/master/docker/ibmcom-datapower-example) instead.

## Usage:

0) Meet the documented DataPower Gateway Virtual Edition minimum
requirements.  Four cores and 8 GB RAM is a good starting place.
Have Docker already installed and working properly. Additionally,
a browser will have to be available for accepting the license.
The experience will be best if Firefox is available on the build
host. This example is Makefile based; GNU make is required.

1) Download the DataPower Gateway Virtual Edition Debian files from
IBM PassPort Advantage

2) Name the files "ibm-datapower-common.deb" and "ibm-datapower-image.deb"
respectively. The process works the same way no matter which variety of
image deb is used.

3) Run `make`. It will:
  * `docker build` -- Create a DataPower "factory image" using the sample
      Dockerfile from the debs
  * `docker run` -- Run DataPower in a container
  * `docker exec` -- Use the DataPower CLI to answer initial setup questions
  * Try to use Firefox to accept the license.
  * `docker stop` -- Gracefully the DataPower container
  * `docker commit` -- Save the license-accepted container as a "base image"
  * `docker rm` -- Delete the license-accepted container, we don't need it
      any more.
  * `docker tag` -- tag the image as "latest".

4) Try out your new "base image"
  * `make run` -- Run a container from the base image, named "datapower" by default
  * `make cli` -- Access the cli of the running "datapower" container
  * `make gui` -- Access the DataPower WebGUI
  * `make rm`  -- Stop and remove the container "datapower"
  * Use it as the FROM in another Docker project!

The Makefile itself contains extensive, detailed notes.

This is the first step in taking advantage of a Dockerized
DataPower Gateway.  The next step is to create another image based upon
this image.
