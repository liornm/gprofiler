#!/usr/bin/env bash
#
# Copyright (c) Granulate. All rights reserved.
# Licensed under the AGPL3 License. See LICENSE.md in the project root for license information.
#
set -euo pipefail

VERSION=v2.0g4
GIT_REV=9d29169e34abc004f534a85ba6a4cf8920250381
OUTPUT=async-profiler-2.0-linux-x64.tar.gz

git clone --depth 1 -b "$VERSION" https://github.com/Granulate/async-profiler.git && cd async-profiler && git reset --hard "$GIT_REV"
set +eu  # this funny script has errors :shrug:
source scl_source enable devtoolset-7
set -eu
make release

# add a version file to the build directory
echo -n "$VERSION" > async-profiler-version
gunzip "$OUTPUT"
tar -rf "${OUTPUT%.gz}" --transform s,^,async-profiler-2.0-linux-x64/build/, async-profiler-version
gzip "${OUTPUT%.gz}"
