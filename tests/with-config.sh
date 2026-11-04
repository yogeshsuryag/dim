#!/usr/bin/env bash
set -euo pipefail
# Mount the fixture where native Omarchy actually reads it; never change HOME.
fixture=${XDG_CONFIG_HOME:?}/omarchy
test_dir=${DIM_TEST_ROOT:-${MOCK_LOG%/*}}
mkdir -p "$fixture"
exec bwrap --die-with-parent --ro-bind / / --dev /dev --proc /proc \
  --bind "$test_dir" "$test_dir" \
  --bind "$fixture" "$HOME/.config/omarchy" -- "$@"
