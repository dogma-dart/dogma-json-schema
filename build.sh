#!/bin/sh

git clone https://github.com/dogma-dart/dogma-codegen.git ../dogma-codegen
git clone https://github.com/dogma-dart/dogma-data.git ../dogma-data

dart --version

pub install

pub global activate linter
pub global run linter .
