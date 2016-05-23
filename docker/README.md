# DataPower on Docker ![DataPower on Docker Logo](https://sketch.io/render/sk-5717d8f02b1b9.png)
### [[Release Notes Here]](http://www-01.ibm.com/common/ssi/ShowDoc.wss?docURL=/common/ssi/rep_ca/4/897/ENUS216-024/index.html&request_locale=en)
## Overview              

Docker makes it easier to build, manage and run composite applications in a world where there is increasing interest in the benefits of  micro-services architecture, Continuous Deployment and Continuous Integration and DevOps practices. With DataPower on Docker, we can enjoy the usual benefits of Docker containers such as being able to automate the build process of our images from version control artifacts, having immutable images for reproducible builds and running multiple containers per host.

It is important to realize that these benefits are good in isolation, but much more powerful as part of the greater Docker ecosystem, which includes a growing variety of solution suites and tools to reduce friction when developing, testing, and publishing distributed applications. These features provide motivation to enable DataPower workflows that use the synergy of DataPower running not only as a container, but as a component of a distributed application.
___

## Introduction
 The DataPower projects in GitHub demonstrate non-definitive, sample workflows with DataPower on Docker that range from quickly building a base image with DataPower firmware, to including externally managed configuration. Other projects demonstrate more advanced techniques to efficiently use the union file system to save disk space when building images.

## The projects include:

### deb2img
Starting from the IBM DataPower Debian packages (available from PPA), build a license-accepted 'base' image.
[[Debian based image]](https://github.com/ibm-datapower/datapower-labs/tree/master/docker/deb2img)
[[sample Dockerfile]](https://github.com/ibm-datapower/datapower-labs/blob/master/docker/deb2img/Dockerfile)

### rpm2img
This is analogous to _**deb2img**_. Starting with the rpm packages (available from PPA), build a license-accepted 'base' image.
[[RPM based image]](https://github.com/ibm-datapower/datapower-labs/tree/master/docker/rpm2img)
[[sample Dockerfile]](https://github.com/ibm-datapower/datapower-labs/blob/master/docker/rpm2img/Dockerfile)
### customer-commit
Starting from a DataPower base image, demonstrate how to add intrinsic DataPower artifacts (for example: crypto-material, users, passwords).

### customer-build
Starting from the DataPower base image, demonstrate core development and build workflows such as live editing of Gatewayscript or XSLT in the host, manage DataPower configuration in version control, and consume environment variables.

### customer-optmized
A more advanced sample, customer-optimized is akin to deb2img and customer-commit but is more efficient in how it decides to commit changes to the image, resulting in a smaller image size.


## Prerequisites

If you previously installed a version of the Docker Engine, make sure that you are now using version 1.8 or 1.9. To see your docker-engine version, run:  ``` docker version ```. For more information about setting up the host environment, refer to [the official documentation](http://www.ibm.com/support/knowledgecenter/SS9H2Y_7.5.0/com.ibm.dp.doc/welcome.html?lang=en)

___

## License
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
