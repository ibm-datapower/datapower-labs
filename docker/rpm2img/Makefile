# Instructions:
#
# 1) Place the DataPower RPM packages in the docker build directory
# 2) Rename the packages ibm-datapower-common.rpm and ibm-datapower-image.rpm
#    respectively.
# 3) make build -- this will give you a docker image of a just-installed
#    DataPower Gateway. This is the DataPower Factory Image.
# 4) make evolve -- this starts the DataPower Gateway in a container;
#    It runs the factory image so the license can be accepted and initial
#    configuration performed.  This will evolve into the base image.
# 5) make cli -- Connect to the DataPower via the CLI.  Initially this
#    is used for selecting secure backup and common criteria mode,
#    later it can be used for testing the resulting image.
# 6) make gui -- asks Firefox to open the DataPower WebGUI
#    Initially, this is required for accepting the license.  After, it can
#    be used for testing the result. Note that 'make gui' will stop running
#    instances of firefox.
# 7) Accept the license in the DataPower WebGUI
# 8) make stop.  This stops the DataPower container but does not delete it.
# 9) make commit -- creates a docker image of the license-accepted
#    DataPower Gateway. This image is called "-base" because it will be
#    used as the base for future DataPower images.
# 10) make run -- runs the -base image.
# 11) make tag -- tags the license-accepted image from the previous step
#    with the :latest suffix.
#
# This can be shortened to 3 steps:
# 1) make build evolve cli gui
# 2) accept license
# 3) make stop commit rm tag
#
# And an optional test step, to verify that the resulting image works properly.
# 4) make run cli rm
#
# For the especially brave, the whole process can be shortened to a single step:
# A) Use the "all" target: "make" or "make all".
# B) optional "make run cli rm" to test
#
# At the end of this process, you will have a DataPower Docker image suitable
# for use as a base for application development.
#
# A note on naming conventions:
# * The registry defaults to USER.  Override at will. Add the registry prefix.
# * The repository defaults to the package name of the -image rpm, with the
#   trailing "-image" removed and "-factory" appended.
# * The default name for a running container is "datapower".  Override at will,
#   remember that the name of a container must be unique on this docker engine.
# * The repository of the committed image is the same as the name of the built image
#   with the addition of the "-base" suffix.  This is because the committed,
#   license-accepted DataPower gateway is the image that will serve as the base
#   for other DataPower Gateway images created with docker build.
# * The tagged image is the same repository as the "-base" repository, except that the
#   tag is "latest".
#
# A note on working with multiple containers:
# * The default container name is "datapower"
# * The "CONTAINER_NAME" variable can be specified on make or as an environment
#   variable.
# * The "CONTAINER_HTTP_PROXY" variable can be specified to enable docker image
#   building behind a firewall, e.g. CONTAINER_HTTP_PROXY=http://9.138.237.58:3128
#      (you'll probably need http_proxy in /etc/default/docker as well)
#      (e.g. export http_proxy="http://9.138.237.58:3128")
# * One option is to have a window for each of several DataPower containers
# * And set CONTAINER_NAME=datapowerX, where X is 1..n, and is unique in each
#   window.

# Windows notes:
# 1) Use cygwin
# 2) Make sure to place your build dir somewhere under c:\users or /cygdrive/c/users,
#    it's the only way Docker volumes work as of this writing
# 3) Make sure that you can use Docker kMj
BLDDIR=$(subst /cygdrive,,$(shell pwd))
REGISTRY ?= $(USER)
PACKAGENAME ?= datapower
FACTORYREPOSITORY=$(PACKAGENAME)-factory
BASEREPOSITORY=$(PACKAGENAME)-base
REPOSITORY=$(BASEREPOSITORY)
TAG ?= 0.1
CONTAINER_NAME ?= datapower

MAXWAIT=120

RUNFLAGS = --restart=on-failure --privileged -P

.PHONY: all build shell evolve run rm cli gui clean logs commit tag stop

all: build evolve cli gui stop commit rm tag

# Make sure a listener is on a port before trying to connect with it
# Inside the container, check netstat once a second until the TCP
# port is in LISTEN.
define wait-for-listener
	@docker exec -it $(CONTAINER_NAME) /bin/bash -c \
	  'MSG="Waiting for port $(LISTENPORT) listener"; \
	  NL=""; \
	  for (( i=0, RC=1; i<$(MAXWAIT); i++ )); do \
	    netstat -ln | grep -q "^tcp.*:$(LISTENPORT).*LISTEN" \
	      && { RC=0; break; }; \
	    echo -n $$MSG; \
	    MSG=.; \
	    NL="\n"; \
	    sleep 1; \
	  done; \
	  echo -ne "$$NL"; \
	  exit $$RC'
endef

build: Dockerfile ibm-datapower-common.rpm ibm-datapower-image.rpm
	docker build --pull -t $(REGISTRY)/$(FACTORYREPOSITORY):$(TAG) .

evolve: REPOSITORY=$(FACTORYREPOSITORY)
evolve: run 
	@echo "#############################################################"
	@echo "## It is a manual process to turn a factory image into a   ##"
	@echo "## base image.  You must perform the fillowing steps:      ##"
	@echo "##                                                         ##"
	@echo "## 1) In the CLI, answer the initial questions DataPower   ##"
	@echo "## normally asks upon reinitialization, such as enabling   ##"
	@echo "## secure backup and common criteria mode.  As soon as     ##"
	@echo "## you receive a DataPower prompt, type 'exit'.            ##"
	@echo "##                                                         ##"
	@echo "## 2) In the WebGUI, accept the license. When you are      ##"
	@echo "## again presented with the DataPower login screen, close  ##"
	@echo "## firefox.                                                ##"
	@echo "#############################################################"

shell:
	docker exec -it $(CONTAINER_NAME) /bin/bash

# Start the CLI via telnet. But first wait up to $(MAXWAIT) sec for telnet to come up.
cli: LISTENPORT=2200
cli:
	$(wait-for-listener)
	docker exec -it $(CONTAINER_NAME) telnet 127.0.0.1 2200 ; true

gui: LISTENPORT=9090
gui:
	$(wait-for-listener)
	killall firefox 2>/dev/null; firefox https://127.0.0.1:$(shell docker inspect --format='{{(index (index .NetworkSettings.Ports "$(LISTENPORT)/tcp") 0).HostPort}}' $(CONTAINER_NAME) 2>/dev/null) > /dev/null 2>&1

run:
	docker run -d --name $(CONTAINER_NAME) $(RUNFLAGS) $(REGISTRY)/$(REPOSITORY):$(TAG)

stop:
	docker stop -t $(MAXWAIT) $(CONTAINER_NAME) || true

rm: stop
	docker rm $(CONTAINER_NAME) || true

clean:

logs:
	docker logs $(CONTAINER_NAME) 2>&1

commit:
	docker rmi $(REGISTRY)/$(BASEREPOSITORY):$(TAG) >/dev/null 2>&1 || true
	docker commit $(CONTAINER_NAME) $(REGISTRY)/$(BASEREPOSITORY):$(TAG)

tag:
	docker tag -f $(REGISTRY)/$(BASEREPOSITORY):$(TAG) $(REGISTRY)/$(BASEREPOSITORY):latest
