#!/bin/bash

set -x

for f in $(find /datapower/start -type f)
do
  echo "Processing $f"
  . "$f"
  set -x
  echo
done

exec /opt/ibm/datapower/datapower-launch
