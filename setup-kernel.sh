#!/bin/bash

if [[ "$USER" != "root" ]]; then
  echo "script must run as root"
  exit 1
fi

set -eux

export DEBIAN_FRONTEND=noninteractive

apt-get install linux-headers-4.7.0-07282016-torvalds+ linux-image-4.7.0-07282016-torvalds+
