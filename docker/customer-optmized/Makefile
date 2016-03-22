# A more advanced example that keeps the image size smaller through careful
# use of Docker volumes and commit. The strategy is to build a single 
# Docker container up by issuing standard commands then performing a
# Docker commit at the end.
#
# Think of this example as deb2img and customer-commit combined. It performs
# both roles but in a single container that becomes a single image.
# This allows the image to be constructed without without unnecessarily
# increasing the size of the docker image along the way.
#
# The resulting image is called customer-commit, so it can be used directly
# by the customer-build example.
#
# If you use the rpm2img/deb2img then customer-commit examples, you end up
# with something that is functionally similar to using this example, except
# the size of the image will be far less with this example.

RESULTREGISTRY ?= $(USER)/
RESULTREPOSITORY ?= customer-commit
RESULTTAG ?= 0.1

REGISTRY ?= $(USER)/
RUNREGISTRY ?= $(USER)/
RUNREPOSITORY ?= $(RESULTREPOSITORY)
RUNTAG ?= 0.1
CONTAINER_NAME ?= customer-optimized-2
RUNFLAGS ?= --privileged --publish-all
MAXWAIT ?= 600
RUNDETACH ?= true

FROM ?= ubuntu:trusty

.PHONY: all shell run rm cli gui clean logs tag stop fixate

GENERATEDFILES = datapower/local/server.crt \
                 datapower/local/server.key \
                 datapower/local/foo/server.crt \
                 datapower/local/foo/server.key \
                 datapower/config/password-map.cfg

all: ubuntu
deb: clean installdeb install acceptlicense password commit tagdeb
rpm: clean installrpm install acceptlicense password commit tagrpm

.PHONY: ubuntu
ubuntu: FROM=ubuntu:trusty
ubuntu: deb

.PHONY: centos
centos: FROM=centos:7
centos: rpm

.PHONY: rhel
rhel: FROM=rhel7.2:latest
rhel: rpm

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

define wait-for-stop
	@docker exec -it $(CONTAINER_NAME) /bin/bash -c \
	  'MSG="Waiting for DataPower processes to stop"; \
	  NL=""; \
	  for (( i=0, RC=1; i<$(MAXWAIT); i++ )); do \
	    ps aguxwww | grep -v grep | grep -q "datapower-launch" \
	      || { RC=0; break; }; \
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
  DP_DOCKER_PROMPTHOSTS=$(DP_DOCKER_HOST) $(shell hostname -f) $(shell hostname -I)
else
  # remove the leading tcp://, then replace the : with a " " so we have
  # 2 words.  Lastly take just the first word, which is just the IP address
  # portion of the DOCKER_HOST.
  DP_DOCKER_HOST=$(firstword $(subst :, ,$(patsubst tcp://%,%,$(DOCKER_HOST))))
  DP_DOCKER_PROMPTHOSTS=$(DP_DOCKER_HOST)
endif

.PHONY: installdeb
installdeb: bldsrc/ibm-datapower-common.deb bldsrc/ibm-datapower-image.deb $(GENERATEDFILES)
	touch datapower/running
	rm -f ./datapower/config/evolve.enabled
	docker run -d --privileged --name $(CONTAINER_NAME) \
	    -v $(PWD)/bldsrc:/bldsrc \
            -v $(PWD)/datapower:/datapower \
	    -p 9090 \
	    $(FROM) \
	    /bin/sh -c 'while [ -e /datapower/running ]; do sleep 1; done'
	docker exec $(CONTAINER_NAME) mkdir -p /datapower/config /datapower/local
	docker exec $(CONTAINER_NAME) apt-get update
	docker exec $(CONTAINER_NAME) apt-get -y install kpartx schroot telnet psmisc
	docker exec $(CONTAINER_NAME) dpkg -i /bldsrc/ibm-datapower-common.deb /bldsrc/ibm-datapower-image.deb

.PHONY: installrpm
installrpm: bldsrc/ibm-datapower-image.rpm bldsrc/ibm-datapower-common.rpm $(GENERATEDFILES)
	touch datapower/running
	rm -f ./datapower/config/evolve.enabled
	docker run -d --privileged --name $(CONTAINER_NAME) \
	    -v $(PWD)/bldsrc:/bldsrc \
            -v $(PWD)/datapower:/datapower \
	    -p 9090 \
	    $(FROM) \
	    /bin/sh -c 'while [ -e /datapower/running ]; do sleep 1; done'
	docker exec $(CONTAINER_NAME) mkdir -p /datapower/config /datapower/local
	docker exec $(CONTAINER_NAME) yum -y update
	docker exec $(CONTAINER_NAME) yum -y install ftp://ftp.muug.mb.ca/mirror/fedora/epel/7/x86_64/s/schroot-1.6.5-5.el7.x86_64.rpm 
	docker exec $(CONTAINER_NAME) yum -y install kpartx telnet net-tools psmisc
	docker exec $(CONTAINER_NAME) yum -y install /bldsrc/ibm-datapower-image.rpm
	docker exec $(CONTAINER_NAME) yum -y install /bldsrc/ibm-datapower-common.rpm

.PHONY: install
install:
	docker exec $(CONTAINER_NAME) sed -i -e '/^web-mgmt/,/^exit/s/admin-state.*/admin-state "enabled"/g' /opt/ibm/datapower/datapower-external.cfg
	docker exec $(CONTAINER_NAME) /bin/sh -c 'echo "DataPowerConfigDir=/datapower/config" >> /opt/ibm/datapower/datapower.conf'
	docker exec $(CONTAINER_NAME) /bin/sh -c 'echo "DataPowerLocalDir=/datapower/local" >> /opt/ibm/datapower/datapower.conf'
	docker exec $(CONTAINER_NAME) /bin/sh -c 'echo "DataPowerCpuCount=4" >> /opt/ibm/datapower/datapower.conf'
	docker exec $(CONTAINER_NAME) /bin/sh -c 'echo "DataPowerMemoryLimit=8192" >> /opt/ibm/datapower/datapower.conf'
	docker exec $(CONTAINER_NAME) sed -i -e '/^cli telnet/iexec config://evolve.cfg' /opt/ibm/datapower/datapower-external.cfg
	docker exec $(CONTAINER_NAME) /opt/ibm/datapower/datapower-docker-build.sh
	docker exec $(CONTAINER_NAME) /bin/sh -c 'rm /opt/ibm/datapower/*.img.gz'
	docker exec -d $(CONTAINER_NAME) /opt/ibm/datapower/datapower-launch

.PHONY: acceptlicense
acceptlicense: LISTENPORT=2200
acceptlicense: WEBGUIPORT=$(shell docker inspect --format='{{(index (index .NetworkSettings.Ports "9090/tcp") 0).HostPort}}' $(CONTAINER_NAME)) 
acceptlicense:
	@echo "#############################################################"
	@echo "## It is a manual process to turn a factory image into a   ##"
	@echo "## base image.  You must now answer the initial questions  ##"
	@echo "## DataPower normally asks upon initialization, such as    ##"
	@echo "## enabling secure backup and common criteria mode. You    ##"
	@echo "## will also be prompted to change the DataPower password. ##"
	@echo "## As soon as you receive a DataPower prompt, issue the    ##"
	@echo "## command 'exit'. There is no need to enable the WebGUI,  ##"
	@echo "## that step has already been performed.                   ##"
	@echo "#############################################################"
	$(wait-for-listener)
	touch ./datapower/config/evolve.enabled
	docker exec -it $(CONTAINER_NAME) telnet 127.0.0.1 2200 ; true
	firefox https://$(DP_DOCKER_HOST):$(WEBGUIPORT) > /dev/null 2>&1 &
	@echo "#############################################################"
	@echo "## In the WebGUI, please accept the DataPower license.     ##"
	@echo "## After you have accepted the license, wait until you     ##"
	@echo "## are again presented with a login prompt.                ##"
	@echo "##                                                         ##"
	@echo "## Only after you see the DataPower login prompt should    ##"
	@echo "## you press 'Enter' in this screen to continue.           ##"
	@echo "##                                                         ##"
	@echo "## If a browser does not open automatically, you must      ##"
	@echo "## point an appropriate browser to port $(WEBGUIPORT)             ##"
	@echo "## of the Docker host using https in order to accept the   ##"
	@echo "## license manually.                                       ##"
	@echo "##                                                         ##"
	@echo "## Your host identifies itself as:                         ##"
	@echo "## $(DP_DOCKER_PROMPTHOSTS)"
	@echo "##                                                         ##"
	@echo "## Press 'Enter' ONLY after BOTH accepting the license     ##"
	@echo "## AND being prompted with a new login screen!             ##"
	@echo "#############################################################"
	@bash -c "read"
	docker exec $(CONTAINER_NAME) sed -i -e '/^exec config:.*evolve.cfg/d' /opt/ibm/datapower/datapower-external.cfg
	@echo "**** $@ complete ****"

include Makefile.secrets
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


.PHONY: password
password: $(foreach user,$(DPUSERS),password-$(user))
	@echo "**** $@ complete ****"

datapower/local/server.crt datapower/local/server.key datapower/local/foo/server.crt datapower/local/foo/server.key:
	mkdir -p datapower/local/foo
	cd datapower/local && rm -f server.crt server.csr server.key
	cd datapower/local && openssl genrsa -passout pass:$(DPPASS_CRYPTO) -des3 -out server.key 4096
	cd datapower/local && printf "$(DN_CountryCode)\n$(DN_State_Province)\n$(DN_City)\n$(DN_Organization)\n$(DN_OrgUnit)\n$(DN_CommonName)\n$(DN_EmailAddress)\n\n\n" | \
	    openssl req -passin pass:$(DPPASS_CRYPTO) -new -key server.key -out server.csr
	cd datapower/local && openssl x509 -passin pass:$(DPPASS_CRYPTO) -req -days 365 -in server.csr -signkey server.key -out server.crt
	cp datapower/local/server.key datapower/local/foo/server.key
	cp datapower/local/server.crt datapower/local/foo/server.crt

datapower/config/password-map.cfg:
	mkdir -p datapower/config
	rm -f $@; touch $@; chmod 600 $@
	echo "crypto" > $@
	echo "  add password-map foo secretfoo" >> $@
	echo "  add password-map bar secretbar" >> $@
	echo "  add password-map crypto $(DPPASS_CRYPTO)" >> $@
	echo "exit" >> $@

commit:
	docker rmi $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG) >/dev/null 2>&1 || true
	docker exec $(CONTAINER_NAME) killall datapower-launch || true
	$(wait-for-stop)
	rm -f datapower/running
	docker stop -t $(MAXWAIT) $(CONTAINER_NAME) || true
	docker commit --change='CMD ["/opt/ibm/datapower/datapower-launch"]' -c "EXPOSE 9090" $(CONTAINER_NAME) $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG)
	@echo "**** $@ complete ****"

#####################################

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

run:
	docker run --detach=$(RUNDETACH) --name $(CONTAINER_NAME) $(RUNFLAGS) $(RUNREGISTRY)$(RUNREPOSITORY):$(RUNTAG) $(CONTAINER_CMD)

stop:
	rm -f datapower/running
	docker stop -t $(MAXWAIT) $(CONTAINER_NAME) || true

rm: stop
	docker rm $(CONTAINER_NAME) || true

kill:
	docker kill $(CONTAINER_NAME) || true

clean: rm
	sudo rm -rf ./datapower/config/foo/foo.cfg ./datapower/config/auto-startup.cfg ./datapower/config/autoconfig.cfg ./datapower/config/evolve.enabled

.PHONY: cleaner
cleaner: clean
	rm -f $(GENERATEDFILES)
	find datapower/ -type f ! -name evolve.cfg -print0 | xargs -0 --no-run-if-empty rm -f

# Fix permissions and ownership.
# If new docker-created root files are present; save them.
.PHONY: fixate
fixate:
	find datapower/ -user root -print0 | xargs -0 --no-run-if-empty sudo chown --no-dereference --reference=.

.PHONY: logs
logs:
	docker logs $(CONTAINER_NAME) 2>&1

# When we tag, add identifying information about the DataPower packages that are installed.
.PHONY: tagdeb
tagdeb: DPVERSION=$(subst +,-,$(shell docker run --rm -it $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG) dpkg-query --show --showformat='$${Version}' ibm-datapower-*image ))
tagdeb: DPPACKAGE=$(subst -image,,$(subst ibm-datapower-,,$(subst ibm-datapower-image,,$(subst +,-,$(shell docker run --rm -it $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG) dpkg-query --show --showformat='$${Package}' ibm-datapower-*image )))))
tagdeb: FROMID=ubuntu
tagdeb: tag

.PHONY: tagrpm
tagrpm: DPVERSION=$(subst +,-,$(shell docker run --rm -it $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG) /bin/sh -c "rpm -qa --queryformat '%{name} %{version}\n' | grep '^ibm-datapower-.*image' | cut -d' ' -f2 "))
tagrpm: DPPACKAGE=$(subst -image,,$(subst ibm-datapower-,,$(subst ibm-datapower-image,,$(subst +,-,$(shell docker run --rm -it $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG) /bin/sh -c "rpm -qa --queryformat '%{name} %{version}\n' | grep '^ibm-datapower-.*image' | cut -d' ' -f1 ")))))
tagrpm: FROMID=$(shell docker run --rm -it $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG) /bin/sh -c '. /etc/os-release; echo $$ID')
tagrpm: tag

.PHONY: tag
tag:
	docker tag -f $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG) $(RESULTREGISTRY)$(RESULTREPOSITORY):latest
	docker tag -f $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG) $(RESULTREGISTRY)$(RESULTREPOSITORY):$(RESULTTAG)-$(DPPACKAGE)-$(DPVERSION)-$(FROMID)

datapower/%:
	mkdir -p $@

