#!/bin/sh
# vergil-archive-keyring post-install (deb postinst and rpm %post).
#
# One .deb serves every Ubuntu release, so the apt source is written here from
# the host's codename rather than shipped as a static file (spec §7.1). Only
# dpkg systems get it; on RHEL the package ships /etc/yum.repos.d/vergil.repo.
set -e

if command -v dpkg >/dev/null 2>&1 && [ -d /etc/apt/sources.list.d ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  if [ -z "${VERSION_CODENAME:-}" ]; then
    echo "vergil-archive-keyring: VERSION_CODENAME is not set in /etc/os-release; cannot write the apt source" >&2
    exit 1
  fi
  cat > /etc/apt/sources.list.d/vergil.sources <<EOF
Types: deb
URIs: https://vergil-project.github.io/packages/deb
Suites: ${VERSION_CODENAME}
Components: main
Signed-By: /usr/share/keyrings/vergil-archive-keyring.asc
EOF
fi
