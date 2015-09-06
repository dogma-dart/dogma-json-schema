#!/bin/sh
set -ex

# Clone dependencies
git clone https://github.com/dogma-dart/dogma-codegen.git ../dogma-codegen
git clone https://github.com/dogma-dart/dogma-data.git ../dogma-data

# Get version
dart --version

# Install dependencies
pub install

# Run the linter
pub global activate linter
pub global run linter .
