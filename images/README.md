# CyberArk Demo Images

[![Images CI Status](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml/badge.svg)](https://github.com/assafjh/cybr-demos/actions/workflows/images.yml)

This directory contains the Dockerfiles and build contexts for all the custom container images used across the various demonstrations in this repository.

All images are automatically built, linted (Hadolint), smoke-tested, and pushed to the GitHub Container Registry (GHCR) via a single unified workflow: `.github/workflows/images.yml`.

Thanks to `paths-filter`, whenever a change is detected in one of the image subdirectories, the CI pipeline dynamically resolves the changes and builds **only** the affected images.