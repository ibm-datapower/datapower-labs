# Purpose

A more advanced sample, customer-optimized is functionally similar to
deb2img and customer-commit combined but is more careful with image commits to
try to keep the image size as small as possible.
Such a workflow avoids unnecessarily increasing the size of the image

NOTICE: This is a legacy example that does not take advantage of DataPower Gateway for Docker. Consider using the [ibmcom-datapower-example](https://github.com/ibm-datapower/datapower-labs/tree/master/docker/ibmcom-datapower-example) instead.

## Usage

Files:

* bldsrc/  - Working directory where to place ibm-datapower-image.deb and ibm-datapower-common.deb
or respective rpm files.

* Makefile - Automates the workflow steps

* Makefile.secrets - Imported by `Makefile`, sets user passwords

* datapower/config - Config directory with mapping inside DataPower's `config:`` directory
, mounted as a Docker volume in this example.
