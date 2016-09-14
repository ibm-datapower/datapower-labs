# Purpose
Use the [IBM DataPower Gateway for Docker](https://hub.docker.com/r/ibmcom/datapower/) to demonstrate basic concepts of using the DataPower Gateway in conjunction with a Docker friendly software development life cycle.

This is applicable *only* to IBM DataPower Gateway for Docker which was introduced in DataPower v7.5.2. It does *not* apply to the IBM DataPower Gateway for Linux which is delivered as Debian and RPM packages. While the sample application is the same, the DataPower platform is different and the development speed, deployment speed, and Docker SDLC integration is much better when using DataPower for Docker instead of DataPower for Linux.

This project demonstrates how one might:

* Use the DataPower WebGUI as an IDE for DataPower configuration
* Easily edit Gatewayscript or xsl files such that they are immediately
  available inside DataPower with no further action required
* Use version control with DataPower configuration with the docker
  run --volume flag
* Customize containers at run time so they can consume Docker-provided
  environment variables and honor the docker run --link flag
* Build and test new images
* Use the same project directly from version control for both development and deployment
* Have `web-mgmt` available for development but disable all management interfaces for deployment -- all management that needs to be done can be done from the Docker console.
* Have a well-known password (`supersecret`) for development but use a randomly generated password for deployment

## Contents

./.dockerignore -- prevent artifacts from the `rundev` target from leaking into the `build`.

./.gitignore -- mark the files that are not under version control

./Makefile -- the orchestrator. See comments for details of operation.

./README.md -- this file

./src/drouter/config/auto-startup.cfg -- The saved DataPower default domain configuration file. It is updated by a developer via `write mem` in the CLI or save in `web-mgmt`.

./src/drouter/config/auto-user.cfg -- The DataPower config file for users. This one contains the `admin` user with the ciphertext password that corresponds to `supersecret`

./src/drouter/config/foo/foo.cfg -- The saved DataPower domain foo
configuration. It is updated by a developer via `write mem` in the CLI or save in `web-mgmt`.

./src/drouter/local/foo/hello-too.js -- Gatewayscript in support of the domain foo Multi-Protocol gateway

./src/drouter/start.sh -- Startup script, runs the `/start/*` scripts and then starts drouter itself.  This is the Dockerfile CMD for this image, so all the scriptlets in the `./src/drouter/start/` directory are run before `/bin/drouter` is exec'd.

./src/drouter/start/debug.sh -- Generates a log target at run time if the environment variable DEBUG is set, such as 'make DEBUG=true
run' or 'make DEBUG=true rundev'. If set, this causes DataPower configuration in both the `default` and `foo` domains to be run via `include-config` that enables debug log targets. This is controlled by an environment variable and generates an `include-config` file.

./src/drouter/start/loadbalancer-group.sh -- Generates the `loadbalancer-group` used by domain `foo` for back end servers.  The back end servers are all linked Docker containers and run on port 8080. An `include-config` reads the configuration created by this script. This is controlled by an environment variable and generates an `include-config` file.

./src/start/reset-password.sh -- Generates `config:///reset-password-imp.sh`, but only when a random password is desired for `admin`. It knows when this is desired by looking at an environment variable, which is set by the `Makefile` when the `run` target is used, but not when `rundev` is used. This is controlled by an environment variable and generates an `include-config` file.

./src/start/vbox-inotify-workaround.sh -- Disables Gatewayscript file caching when `rundev` is used, but only if the Docker Engine is remote to the Docker Client. Without this setting, when changes are made `*.js` files DataPower continues to use the old version. This is controlled by an environment variable and generates an `include-config` file.

./src/start/web-mgmt.sh -- Turns on `web-mgmt` for the developer but not when deployed. When in development, the `web-mgmt` is effectively DataPower's IDE. But the IDE is not needed or wanted for deployment, so `web-mgmt` is only enabled when the `rundev` target is used and not when the `run` target is used. This is controlled by an environment variable and generates an `include-config` file.

## Concepts

The goal of this project is to completely, utterly, and unashamedly embrace the Docker SDLC (Software Development Life Cycle). At the same time, it is intended to be an extremely simple example with minimal prerequisites to demonstrate how DataPower may fit into an orchestration environment.

For our orchestrator, we will use a simple Makefile. It has the ability to automate all the actions that we want to demonstrate. The focus is on how to build an application with DataPower -- it is an admittedly very interesting exercise to extend this example into the CI/CD or orchestration environment of your choice.

A description of selected `Makefile` targets:
- `build`
  - `docker build` the image
  - Used by a developer for unit test
  - Used by a builder to build an image
  - What the CI/CD system would do to get the Docker image for this DataPower Gateway
- `rundev`
  - run `ibmcom/datapower` as a developer would.
  - `web-mgmt` is enabled;
  - volumes are used for configuration so that `write mem` or `Save config` inside DataPower cause the correct files to be saved in the source tree.
- `run`
  - runs the built image generated by this project
  - Used by a developer for unit test
  - Something similar would be done by CI/CD to run tests, bring up in production, etc
- `test`
  - runs the test harness to make sure that the container is working properly.
  - This is a stand in for any kind of automated testing that would be present in an orchestration environment.
- `tag`
  - Adds the `latest` tag to the output image
  - This indicates a good build that has passed `test`.
- `clean` `cleaner`
  - Remove generated files.
  - `clean` should always be run between `rundev` and `build`
  - `cleaner` also removes any generated keys.
- `gui`, `cli`, `shell`
  - Connect to an already-running container on `web-mgmt`, the `cli`, and in `/bin/sh` respectively.
  - There is no `gui` running if using `run`, only for `rundev`.
  - If the password was reset at run time, the generated password will be printed for both `cli` and `gui`. The generated password is harvested from `docker logs`, meaning that anyone with access to Docker could get the password.
- `rm` -- stop and remove running containers from `rundev` or `run`.
- `all` -- `make clean build run test tag`
  - This is the target that the build farm would run when triggered by a checkin
  - This is the target that a developer would use prior to check in
  - The developer would have a different repository than the build farm so there would be no name collisions.

A description of workflow for selected roles:
- Developer role
  1. `rundev`
    - `gui`, `cli` -- change configuration to DataPower itself
    - `shell` -- Work with early startup integration, such as the code that is run before `drouter` is started.
    - `test` -- run the test harness against the running container
    - Repeat until satisfied, then
  1. `all` -- unit test the result, then
  1. Check in changes
- Release Engineering / Build-Farm role
  1. `all` -- Does the complete build including test and tag
  1. `docker push` -- makes the image available beyond the build machine.
    - This could be for the use of the Software Quality Assurance team
    - Could be for release to next steps of Continuous Integration / Continuous delivery
    - At this point, you have a tested, tagged, and pushed image that is ready for the next step of deployment.
