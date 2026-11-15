# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/)
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.1.2] - 2026-11-15

### Bug fixes

- check packages.toml with vrg-package index --check-config (#26)
- keep the last two releases per line so a cached index never names a deleted file (#56)

### CI

- stop passing container-tag to cd-release (#20)
- move the daily ops cron to the 01:xx UTC hour (#53)

### Chores

- turn off Claude Code co-author attribution (#14)
- add the report-only dependabot.yml (#16)
- retire vergil-python3.14.8 from the package index (#21)
- sync the vergil-managed .gitignore block (#25)
- give publish-index runs a descriptive run-name (#27)
- keep one release per line in the package index (#29)
- sync the vergil-managed .gitignore block (#36)
- sync the vergil-managed .gitignore block (#40)
- sync the hook guard shim with the managed copy (#44)
- sync the managed files with the released templates (#51)
- sync the managed .claude/settings.json (#49)

### Documentation

- update status, VM bootstrap owner, and add product onboarding (#12)
- list the per-series python runtimes and keep 1 retention (#32)
- note that the custom validator runs in PR CI as quality / custom (#34)
- steering and settings sweep (epic 558) (#38)
- sync the template's build/ exception line (#42)
- describe the retention-first index build order (#50)

## [1.1.1] - 2026-10-07

### Bug fixes

- restore secrets: inherit so environment secrets reach the reusable workflows (#7)

### Features

- keyring product and index configuration (#3)

## [1.1.0] - 2026-10-06 (not published)

Never tagged or published: the release's `package-sign` job could not read the
signing key (#6). Its changes ship in 1.1.1.

## [1.0.0] - 2026-10-05

### Chores

- step 3 - vergil.toml
- step 4 - config files
- step 6 - CI/CD workflows
