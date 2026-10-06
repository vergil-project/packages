#!/bin/sh
# vergil-archive-keyring post-removal (deb postrm and rpm %postun).
#
# Removes the apt source postinst.sh wrote. deb passes remove/purge on removal
# (and upgrade/... otherwise); rpm passes 0 on erase and 1 on upgrade, so an
# upgrade keeps the source.
set -e

case "$1" in
  remove|purge|0) rm -f /etc/apt/sources.list.d/vergil.sources ;;
esac
