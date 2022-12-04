#!/bin/sh
apt-get update
apt-get install -y --no-install-recommends \
  locales-all

echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
