#!/bin/sh
set -ex

# Get version
dart --version

# Get dependencies
pub global activate coverage
pub global activate linter
pub install

# Run the linter
#pub global activate linter
#pub global run linter .

# Run the tests
dart --checked --observe=8000 test/all.dart & \
pub global run coverage:collect_coverage \
    --port=8000 \
    --out coverage.json \
    --resume-isolates & \
wait

pub global run coverage:format_coverage \
    --package-root=packages \
    --report-on lib \
    --in coverage.json \
    --out lcov.info \
    --lcov
