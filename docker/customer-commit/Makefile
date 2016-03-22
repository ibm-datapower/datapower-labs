# Instructions:
#
# 1) Build the "-base" image image using deb2img or rpm2img
# This can be shortened to 3 steps:
# 2) make
# 3) Use the resulting image as the basis for the customer-build project
#
# A note on naming conventions:
# * The registry defaults to USER.  Override at will. Add the registry prefix.
# * The repository defaults to customer-commit.
# * The default name for a running container is "customer-commit".  Override at will,
#   remember that the name of a container must be unique on this docker engine.
# * The repository of the committed image is the same as the name of the built image
# * The tagged image is the same repository, except the tag is "latest". instead
#   of the value of TAG, which defaults to 0.1.
#
# A note on working with multiple containers:
# * The default container name is "customer-build"
# * The "CONTAINER_NAME" variable can be specified on make or as an environment
#   variable.
# * One option is to have a window for each of several DataPower containers
# * And set CONTAINER_NAME=foo, where foo is unique in each window.
#
# How it works:
#
# We start from a license-accepted but otherwise unconfigured DataPower Docker
# image. The image already uses /datapower/local for local: and /datapower/config
# for config:.
#
# When we docker run the datapower image, we use Docker volumes for 
# datapower-external.cfg and /datapower. The datapower-external.cfg file contains
# DataPower CLI instructions that DataPower processes at startup. We add commands
# to this file that allow us to set up the parts of DataPower that we do not want
# to be visible in the clear-text filesystem of the image or of the container.
#
# Examples of the sorts of things we set up here are users and passwords, keys and
# certs, etc. Broadly speaking, the kinds of things we want to add here are the things
# that cannot be extracted from DataPower once added.
#
# Because we use a docker volume for the container's /datapower directory, we can
# use it for our keys and certs, then we can use the DataPower "copy" command to
# get the cryptomaterial directly from the release engineering machine into
# DataPower without being exposed at any other time.
#
# Once we know this process has completed, which is signaled by the availability
# of services defined later in datapower-external.cfg, the container can be
# stopped and turned into an image with "docker commit".
#
# The "evolve" target in this Makefile performs these operations, which can be
# reduced to running the datapower-base image with the volume options and waiting
# for a DataPower management service to be available. The "build" target then
# depends on evolve, stop, commit and rm.  Meaning that in order to "build" a
# DataPower Gateway docker image with users and keys one runs the previous image using
# special configuration which DataPower receives via docker volumes and
# "docker commits" the result.
#
# This image can then be run and tested.  Once the image's validity is verified,
# it can be tagged as customer-commit:latest for use in the customer-build project.
#
# The point of this step is to add in the secrets.  To this end, the secrets are
# contained in Makefile.secrets.  This contains all the passwords and the
# meta data for generation of keys and certs.  Only the non-annointed will
# generate the keys and certs this way; the release engineering team will have
# the real keys and certs. Developers who are building their own images use
# their own low-value cryptomaterial.
include Makefile.secrets

REGISTRY ?= $(USER)
BASEREPOSITORY ?= datapower-base
RESULTREPOSITORY ?= customer-commit
REPOSITORY = $(RESULTREPOSITORY)
TAG ?= 0.1
CONTAINER_NAME ?= customer-commit

MAXWAIT=600

RUNFLAGS = --privileged -P

.PHONY: all build shell evolve run rundev rm cli gui clean logs commit tag stop password fixate distclean

all: clean evolve password stop commit rm tag
build: all

GENERATEDFILES = datapower/local/server.crt \
                 datapower/local/server.key \
                 datapower/local/foo/server.crt \
                 datapower/local/foo/server.key \
                 datapower/config/password-map.cfg \
                 datapower/config/evolve.cfg

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

# The DOCKER_HOST variable may be unset or may contain tcp://1.2.3.4:1234
# We just want to know the address of the Docker Engine we're talking to
# so it's either the IP address portion of DOCKER_HOST or it's 127.0.0.1.
ifeq '$(DOCKER_HOST)' ''
  DP_DOCKER_HOST=127.0.0.1
else
  # remove the leading tcp://, then replace the : with a " " so we have
  # 2 words.  Lastly take just the first word, which is just the IP address
  # portion of the DOCKER_HOST.
  DP_DOCKER_HOST=$(firstword $(subst :, ,$(patsubst tcp://%,%,$(DOCKER_HOST))))
endif


evolve: RUNFLAGS+=-v $(PWD)/datapower:/datapower -v $(PWD)/datapower-external-evolve.cfg:/opt/ibm/datapower/datapower-external.cfg
evolve: LISTENPORT=2200
evolve: REPOSITORY=$(BASEREPOSITORY)
evolve: TAG=latest
evolve: run $(GENERATEDFILES)
evolve:
	$(wait-for-listener)

define PASSWORD_template
.PHONY: password-$(1)
password-$(1):
	@echo ====== Changing password for user $(1) ======
	@docker exec -it $(CONTAINER_NAME) /bin/bash -c \
	  '{ echo $(1); sleep 0.2; \
             echo "changeme"; sleep 0.2; \
	     if [ "$(1)" = "admin" ]; then \
               echo "top; co; user admin; password"; sleep 0.2; \
               echo "$$(DPPASS_$(1))"; sleep 0.2; \
               echo "$$(DPPASS_$(1))"; sleep 0.2; \
               echo "exit; exit"; sleep 0.2; \
	     else \
               echo "$$(DPPASS_$(1))"; sleep 0.2; \
               echo "$$(DPPASS_$(1))"; sleep 0.2; \
	     fi ; }\
	   | telnet 127.0.0.1 2200'; echo
endef
$(foreach user,$(DPUSERS),$(eval $(call PASSWORD_template,$(user))))

password: $(foreach user,$(DPUSERS),password-$(user))

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
	firefox https://$(DP_DOCKER_HOST):$(shell docker inspect --format='{{(index (index .NetworkSettings.Ports "$(LISTENPORT)/tcp") 0).HostPort}}' $(CONTAINER_NAME)) > /dev/null 2>&1 &

run: $(GENERATEDFILES)
run:
	docker run -d --name $(CONTAINER_NAME) $(RUNFLAGS) $(REGISTRY)/$(REPOSITORY):$(TAG)

stop:
	docker stop -t $(MAXWAIT) $(CONTAINER_NAME) || true

rm: stop
	docker rm $(CONTAINER_NAME) || true

clean:
	sudo rm -rf datapower || rm -rf datapower || true

# When distributing the source, the keys are not included!
distclean: clean
	rm -f server.crt server.csr server.key

# Fix permissions and ownership. Keep Makefile.secrets as private as possible.
# If new docker-created root files are present; save them.
fixate:
	find datapower/ -user root -print0 | xargs -0 --no-run-if-empty sudo chown --reference=.
	chmod a-x,og-rw,u+r Makefile.secrets

logs:
	docker logs $(CONTAINER_NAME) 2>&1

commit:
	docker rmi $(REGISTRY)/$(REPOSITORY):$(TAG) >/dev/null 2>&1 || true
	docker commit $(CONTAINER_NAME) $(REGISTRY)/$(REPOSITORY):$(TAG)

tag:
	docker tag -f $(REGISTRY)/$(REPOSITORY):$(TAG) $(REGISTRY)/$(REPOSITORY):latest

datapower/local/server.crt datapower/local/server.key datapower/local/foo/server.crt datapower/local/foo/server.key: server.crt server.key
	mkdir -p datapower/local/foo
	cp server.crt datapower/local/server.crt
	cp server.key datapower/local/server.key
	cp server.crt datapower/local/foo/server.crt
	cp server.key datapower/local/foo/server.key

server.crt server.key:
	rm -f server.crt server.csr server.key
	openssl genrsa -passout pass:$(DPPASS_CRYPTO) -des3 -out server.key 4096
	printf "$(DN_CountryCode)\n$(DN_State_Province)\n$(DN_City)\n$(DN_Organization)\n$(DN_OrgUnit)\n$(DN_CommonName)\n$(DN_EmailAddress)\n\n\n" | \
	    openssl req -passin pass:$(DPPASS_CRYPTO) -new -key server.key -out server.csr
	openssl x509 -passin pass:$(DPPASS_CRYPTO) -req -days 365 -in server.csr -signkey server.key -out server.crt

datapower/config/password-map.cfg:
	mkdir -p datapower/config
	rm -f $@
	touch $@
	chmod 600 $@
	echo "crypto" > $@
	@echo "  add password-map foo secretfoo" >> $@
	@echo "  add password-map bar secretbar" >> $@
	@echo "  add password-map crypto $(DPPASS_CRYPTO)" >> $@
	echo "exit" >> $@

datapower/config/evolve.cfg:
	mkdir -p datapower/config
	cp evolve.cfg datapower/config/evolve.cfg
