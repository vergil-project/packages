# packages

The signed apt/dnf package repository for vergil-project products, served from
GitHub Pages at <https://vergil-project.github.io/packages>. This repository
also builds and releases `vergil-archive-keyring`, the package that configures
a host to trust and use the repository.

## Table of Contents

- [Status](#status)
- [Overview](#overview)
- [Using the repository](#using-the-repository)
- [Site layout](#site-layout)
- [Repository layout](#repository-layout)
- [How the index is published](#how-the-index-is-published)
- [Signing](#signing)
- [Adding a product](#adding-a-product)
- [License](#license)

## Status

Live. The index is published at <https://vergil-project.github.io/packages>
and serves `vergil-archive-keyring`, `vergil-python3.14.8` and
`vergil-tooling`.

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

On a vergil-managed VM you do not run this by hand: `vrg-vm create` and
`vrg-vm update` perform the bootstrap when they install a released
vergil-tooling, and refuse any key whose primary fingerprint differs from the
one pinned in vergil-tooling. Re-running them is idempotent: stale bootstrap
files are cleaned up first, and a host whose keyring package, key and source
are already in place skips the bootstrap after checking the installed key
against the pinned fingerprint.

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

## Site layout

Paths under <https://vergil-project.github.io/packages>:

| Path | Contents |
|---|---|
| `/deb` | apt repository: suites `noble` and `resolute`, component `main`, architectures `amd64` and `arm64` |
| `/rpm/el9/{x86_64,aarch64}`, `/rpm/el10/{x86_64,aarch64}` | dnf repositories, one per RHEL major release and architecture |
| `/keys/vergil.asc` | the public signing key (primary + current signing subkey) |

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

## Signing

Two signing steps use the repository key, each in its own GitHub environment:

- **Index signing.** `publish-index.yml` signs the apt and dnf metadata in the
  `index-signing` environment (`develop` only). Its call to the reusable
  workflow must use `secrets: inherit`: environment secrets reach a job in a
  cross-repo reusable workflow only that way, and an explicit secrets map
  leaves them empty ([#6](https://github.com/vergil-project/packages/issues/6)).
- **Package signing.** The `vergil-archive-keyring` release itself is signed by
  `cd-release.yml`'s package-sign job in the `package-signing` environment,
  which only `main` can use. `cd.yml` passes `secrets: inherit` for the same
  reason.

## Adding a product

To have a product's packages indexed here:

1. **Declare its package.** The product repository has a `[package]` table in
   its `vergil.toml`, so its release pipeline builds `.deb`/`.rpm` packages and
   attaches them, with a `packages-manifest.json`, to the GitHub Release.
2. **Release through `cd-release.yml`.** Its `cd.yml` calls
   `vergil-project/vergil-actions/.github/workflows/cd-release.yml@v2.1` on
   `main` with:

   ```yaml
   secrets: inherit  # nosemgrep: yaml.github-actions.security.secrets-inherit.secrets-inherit
   ```

   An explicit secrets map leaves the package-sign job's `PACKAGE_SIGNING_KEY`
   empty, so `inherit` is required.
3. **Configure secrets.** The product repository has a `package-signing`
   environment restricted to `main` that holds `PACKAGE_SIGNING_KEY`, and the
   `APP_CLIENT_ID` / `APP_PRIVATE_KEY` secrets that `cd-release.yml` uses to
   dispatch `package-released` to this repository.
4. **List it here.** Add `<org>/<repo>` to `products` in
   [`packages.toml`](packages.toml) and merge the change. The next
   `publish-index.yml` run (dispatched by the product's next release, run
   manually, or the weekly reconcile) picks it up.

Only stable `vX.Y.Z` releases are indexed: drafts, prereleases and `develop-*`
tags are skipped, as are older releases without a `packages-manifest.json`. An
asset passes attestation verification only if it was built by vergil-actions'
`cd-release.yml` from `main`, and every `.rpm` must also carry a valid
signature from the repository key. A verification failure fails the whole
index run rather than skipping the asset, so a product must not publish
stable package releases from any other source.

## License

MIT — see [LICENSE](LICENSE).
