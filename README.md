# packages

The signed apt/dnf package repository for vergil-project products, served from
GitHub Pages at <https://vergil-project.github.io/packages>. This repository
also builds and releases `vergil-archive-keyring`, the package that configures
a host to trust and use the repository.

## Table of Contents

- [Status](#status)
- [Overview](#overview)
- [Using the repository](#using-the-repository)
- [Repository layout](#repository-layout)
- [How the index is published](#how-the-index-is-published)
- [License](#license)

## Status

Early development. The index is published once the first product release has
been indexed.

## Overview

Package files are never committed here. Each product repository builds its
`.deb`/`.rpm` packages in its own release pipeline and attaches them, with a
`packages-manifest.json`, to its GitHub Release. This repository holds the
configuration that turns those releases into a signed package repository.

Indexed products:

| Product | Package |
|---|---|
| [vergil-project/packages](https://github.com/vergil-project/packages) | `vergil-archive-keyring` |
| [vergil-project/vergil-python](https://github.com/vergil-project/vergil-python) | `vergil-python3.X.Y` (pinned Python runtime) |
| [vergil-project/vergil-tooling](https://github.com/vergil-project/vergil-tooling) | `vergil-tooling` |

Supported targets: Ubuntu 24.04 (`noble`) and 26.04 (`resolute`), and RHEL 9
and 10, each on amd64 and arm64.

## Using the repository

The repository is signed with this OpenPGP key:

```text
Primary key  B3A1D804DC03AB036566A4E367861822166ECABE  (certify only)
Signing key  DD67B5BA841442A77A6EC2F704D68CEDB8142851  (subkey)
UID          vergil-project packages <packages@vergil-project.invalid>
```

Trust the **primary** fingerprint. The signing subkey rotates; a rotation ships
as a new `vergil-archive-keyring` release, so a host that trusts the primary
picks it up through ordinary upgrades.

### Verify the key

Download the key and check that it holds exactly one primary key with the
fingerprint above before you trust it:

```bash
curl -fsSL https://vergil-project.github.io/packages/keys/vergil.asc -o /tmp/vergil.asc
gpg --show-keys --with-colons /tmp/vergil.asc | grep -c '^pub:'
# must print 1
gpg --show-keys --with-colons /tmp/vergil.asc | awk -F: '$1 == "fpr" { print $10; exit }'
# must print B3A1D804DC03AB036566A4E367861822166ECABE
```

The same key is committed in this repository as [`keys/vergil.asc`](keys/vergil.asc).

### Ubuntu (apt)

Bootstrap with the verified key, install the keyring package, then remove the
bootstrap files. From then on the keyring package owns the key
(`/usr/share/keyrings/vergil-archive-keyring.asc`) and the apt source
(`/etc/apt/sources.list.d/vergil.sources`, written for your release's codename).

```bash
sudo install -D -m 0644 /tmp/vergil.asc /etc/apt/keyrings/vergil-bootstrap.asc
printf '%s\n' \
  'Types: deb' \
  'URIs: https://vergil-project.github.io/packages/deb' \
  "Suites: $(. /etc/os-release; echo "$VERSION_CODENAME")" \
  'Components: main' \
  'Signed-By: /etc/apt/keyrings/vergil-bootstrap.asc' \
  | sudo tee /etc/apt/sources.list.d/vergil-bootstrap.sources >/dev/null
sudo apt-get update
sudo apt-get install -y vergil-archive-keyring
sudo rm -f /etc/apt/sources.list.d/vergil-bootstrap.sources /etc/apt/keyrings/vergil-bootstrap.asc
sudo apt-get update
```

### RHEL (dnf)

Bootstrap the same way. The keyring package then owns the key
(`/etc/pki/rpm-gpg/RPM-GPG-KEY-vergil`) and the repo file
(`/etc/yum.repos.d/vergil.repo`).

```bash
sudo install -D -m 0644 /tmp/vergil.asc /etc/pki/rpm-gpg/RPM-GPG-KEY-vergil-bootstrap
printf '%s\n' \
  '[vergil-bootstrap]' \
  'name=vergil packages (bootstrap)' \
  'baseurl=https://vergil-project.github.io/packages/rpm/el$releasever/$basearch' \
  'enabled=1' \
  'gpgcheck=1' \
  'repo_gpgcheck=1' \
  'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-vergil-bootstrap' \
  | sudo tee /etc/yum.repos.d/vergil-bootstrap.repo >/dev/null
sudo dnf install -y vergil-archive-keyring
sudo rm -f /etc/yum.repos.d/vergil-bootstrap.repo /etc/pki/rpm-gpg/RPM-GPG-KEY-vergil-bootstrap
```

On a vergil-managed VM, `vrg-package` performs this bootstrap itself and refuses
any key whose primary fingerprint differs from the pinned one.

#### Hosts pinned to a minor RHEL release

The repo URL uses `el$releasever`, which matches the `el9`/`el10` directories on
any host that tracks its major release (the default, and every UBI image). A
host pinned to a minor release (for example with
`subscription-manager release --set=9.4`) has `$releasever` set to `9.4`, so
dnf asks for `el9.4` and fails loudly with a metadata download error.

Minor-pinned hosts are **not supported automatically**. dnf's
`$releasever_major` variable would cover them, but RHEL 9 dnf substitutes it
only from RHEL 9.7 onward; on 9.0 through 9.6 it is left in the URL as literal
text, which would break every unpinned host on those releases. On a pinned
host, replace `$releasever` with the major version (`9` or `10`) in
`/etc/yum.repos.d/vergil.repo` (and in the bootstrap repo file above). The repo
file is a `config(noreplace)` file, so the edit survives keyring upgrades.

## Repository layout

```text
VERSION, vergil.toml        a normal released repo; [package] builds the keyring
packages.toml               products to index, and retention (keep 3 releases
                            per line, the newest 2 major.minor lines)
keys/vergil.asc             the public key (primary + current signing subkey)
packaging/                  nFPM overlay and maintainer scripts for the keyring
.github/workflows/          ci.yml (PR gate, incl. package build/install tests),
                            cd.yml (release), publish-index.yml (the index)
```

## How the index is published

`publish-index.yml` rebuilds the whole site from the product releases each time
it runs: when a product release dispatches `package-released`, on manual
dispatch, and weekly to reconcile a missed dispatch. Before indexing anything
it verifies every asset's build attestation (signed by vergil-actions'
`cd-release.yml` on `main`) and every `.rpm`'s signature, then writes and signs
the apt and dnf metadata and deploys to GitHub Pages. It signs in the
`index-signing` environment, which only the `develop` branch can use.

## License

MIT — see [LICENSE](LICENSE).
