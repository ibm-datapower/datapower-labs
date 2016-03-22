# Purpose
Show the core development and build functions of a DataPower docker project.

This project demonstrates how one might:

* Use the DataPower WebGUI as an IDE for DataPower configuration
* Easily edit Gatewayscript or xsl files such that they are immediately
  available inside DataPower with no further action required
* Use version control with DataPower configuration with the docker
  run --volume flag
* Customize containers at run time so they can consume Docker-provided
  environment variables and honor the docker run --link flag
* Build and test new images

## Usage
Files:

./Makefile -- the orchestrator. See comments for details of operation.

./datapower/config/autoconfig.cfg
./datapower/config/.drouter.cfg -- The saved DataPower default domain
configuration files.  These are saved by DataPower and carried as-is
into version control.

./datapower/config/foo/foo.cfg -- The saved DataPower domain foo
configuration.

./datapower/local/foo/hello-too.js -- Gatewayscript in support of
the domain foo Multi-Protocol gateway

./datapower/start.sh -- Startup script, runs the datapower/start/...
and then starts DataPower itself.  This is the Dockerfile CMD.

./datapower/start/debug.sh -- Generates a log target at run time if
the Docker environment variable DEBUG is set, such as 'make DEBUG=true
run' or 'make DEBUG=true rundev'

./datapower/start/loadbalancer-group.sh -- Generates the loadbalancer-
group used by domain foo for back end servers.  The back end servers
are all linked Docker containers and run on port 8080.
