#!/bin/bash
#
# Work around the VBox/Docker Toolbox inotify bug [1] by disabling
# GatewayScript Cache. Note that if we had XSL, we would want
# to disable caches for that too.
#
# If you're running docker then you'd need to get around the
# DataPower container protections by running as root.
# One way to do that is to run docker with `---user=root`.
#
# [1] https://www.virtualbox.org/ticket/10660

rm -f /datapower/config/vbox-inotify-workaround.cfg

if [ "$DP_VBOX_INOTIFY" = "true" ]
then
  tee /datapower/config/vbox-inotify-workaround.cfg <<-EOF
	# Working around https://www.virtualbox.org/ticket/10660
	# by disabling gatewayscript cache
	# We only do this when using GatewayScript with Docker
	# volumes when we expect to modify the GatewayScript itself
	# and want the changes to be immediately recognized.
	top; diag; set-gatewayscript-cache disable; top; config
	EOF
else
  tee /datapower/config/vbox-inotify-workaround.cfg <<-EOF
	# No need to work around https://www.virtualbox.org/ticket/10660
	EOF
fi
