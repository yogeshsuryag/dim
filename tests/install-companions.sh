#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/jarvis-companions-test.XXXXXX")
export XDG_CONFIG_HOME="$test_root/config"
plugins="$XDG_CONFIG_HOME/omarchy/plugins"

"$repo/install-companions"
for id in jarvis.display jarvis.indicators; do
  diff -qr -- "$repo/companions/$id" "$plugins/$id" >/dev/null
done

unchanged_output=$("$repo/install-companions")
grep -q '^Unchanged: jarvis.display$' <<<"$unchanged_output"
printf 'local modification\n' > "$plugins/jarvis.display/local-only"
if "$repo/install-companions" >"$test_root/conflict.out" 2>&1; then
  echo "expected conflicting companion to fail" >&2
  exit 1
fi
"$repo/install-companions" --replace
[[ ! -e "$plugins/jarvis.display/local-only" ]]
compgen -G "$plugins/jarvis.display.backup.*" >/dev/null
echo "Companion installer checks passed (temporary files: $test_root)."
