#!/bin/bash
# A little helper that finds a -common.deb and a -image.deb that were
# locally built in WORKDIR and creates hard links for use by Makefile.
# Keep this separate, since the Makefile is a fairly customer-ready
# example

set -ex

if [ -z "$WORKDIR" -o ! -d "$WORKDIR" ]
then
  echo FAIL: WORKDIR not set or not a dir
  exit 1
fi

COMMON=$(find $WORKDIR/_build/x86_64/datapower/distro-ng -name \*-common\*.deb | head -1)
IMAGE=$(find $WORKDIR/_build/x86_64/datapower/distro-ng -name \*-image\*.deb | head -1)

if [ "$COMMON" -a "$IMAGE" ]
then
  ln -f "$COMMON" ibm-datapower-common.deb
  ln -f "$IMAGE" ibm-datapower-image.deb
  exit 0
fi

echo FAIL: could not find debian packages
exit 1
