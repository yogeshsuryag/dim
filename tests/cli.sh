#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dim-cli-test.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
export DIM_TEST_ROOT=$tmp MOCK_LOG=$tmp/log
mkdir -p "$tmp/bin"
export PATH="$tmp/bin:$PATH"

cat > "$tmp/bin/omarchy" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  'plugin list --json') cat "$DIM_TEST_ROOT/plugins.json" ;;
  'plugin enable '*) id=${3:?}; printf 'enable %s\n' "$id" >> "$MOCK_LOG"; python3 - "$DIM_TEST_ROOT/plugins.json" "$id" <<'PY'
import os, sys
if os.environ.get('FAIL_ENABLE_ID') == sys.argv[2]:
    print('mock native enable failure', file=sys.stderr)
    sys.exit(1)
import json
p, wanted = sys.argv[1:]
plugins = json.load(open(p))
for plugin in plugins:
    if plugin['id'] == wanted: plugin['enabled'] = True
json.dump(plugins, open(p, 'w'))
PY
    ;;
  'plugin disable '*) id=${3:?}; printf 'disable %s\n' "$id" >> "$MOCK_LOG"; python3 - "$DIM_TEST_ROOT/plugins.json" "$id" <<'PY'
import json, sys
p, wanted = sys.argv[1:]
plugins = json.load(open(p))
for plugin in plugins:
    if plugin['id'] == wanted: plugin['enabled'] = False
json.dump(plugins, open(p, 'w'))
PY
    ;;
  *) echo "unexpected omarchy: $*" >&2; exit 64 ;;
esac
MOCK
cat > "$tmp/bin/omarchy-shell" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_LOG"
case "$*" in
  'oma.dim status') cat "$DIM_TEST_ROOT/state.json" ;;
  'oma.dim toggle') echo disabled ;;
  'oma.dim disable') [[ ${FAIL_DIM_IPC:-} != true ]] || exit 1; echo disabled ;;
  'oma.dim setStrength '*) echo "${3:?}" ;;
  *) echo "unexpected shell IPC: $*" >&2; exit 64 ;;
esac
MOCK
chmod +x "$tmp/bin/omarchy" "$tmp/bin/omarchy-shell"

cat > "$tmp/plugins.json" <<'JSON'
[{"id":"oma.dim","enabled":false},{"id":"oma.display","enabled":true},{"id":"oma.indicators","enabled":true}]
JSON
printf '{"enabled":false,"strength":42}\n' > "$tmp/state.json"

if "$repo/bin/dim" toggle >"$tmp/out" 2>&1; then echo 'disabled toggle unexpectedly succeeded' >&2; exit 1; fi
grep -q 'Dim is disabled. Run: dim enable' "$tmp/out"
if "$repo/bin/dim" strength >"$tmp/out" 2>&1; then echo 'disabled strength unexpectedly succeeded' >&2; exit 1; fi
grep -q 'Dim is disabled. Run: dim enable' "$tmp/out"

if FAIL_ENABLE_ID=oma.dim "$repo/bin/dim" enable >"$tmp/out" 2>&1; then echo 'native enable failure unexpectedly succeeded' >&2; exit 1; fi
grep -q "could not enable 'oma.dim'" "$tmp/out"
: > "$MOCK_LOG"

"$repo/bin/dim" enable >/dev/null
[[ $(grep -c '^enable ' "$MOCK_LOG") == 1 ]]
cp "$MOCK_LOG" "$tmp/enabled-log"
"$repo/bin/dim" enable >/dev/null
cmp "$tmp/enabled-log" "$MOCK_LOG"
"$repo/bin/dim" strength | grep -q 'Strength: 42%'
"$repo/bin/dim" strength 0 >/dev/null
grep -q '^oma.dim setStrength 0$' "$MOCK_LOG"
if "$repo/bin/dim" strength 101 >"$tmp/out" 2>&1; then echo 'invalid strength unexpectedly succeeded' >&2; exit 1; fi
grep -q 'strength must be an integer from 0 to 100' "$tmp/out"
"$repo/bin/dim" status | grep -q 'Dim: enabled, dimming off'
"$repo/bin/dim" toggle >/dev/null
if FAIL_DIM_IPC=true "$repo/bin/dim" disable >"$tmp/out" 2>&1; then echo 'IPC failure unexpectedly succeeded' >&2; exit 1; fi
grep -q 'disabling plugins anyway' "$tmp/out"
[[ $(python3 -c 'import json,sys; print(str(all(not x["enabled"] for x in json.load(open(sys.argv[1])))).lower())' "$tmp/plugins.json") == true ]]
[[ $(grep -c '^disable ' "$MOCK_LOG") == 3 ]]
cp "$MOCK_LOG" "$tmp/disabled-log"
"$repo/bin/dim" disable >/dev/null
cmp "$tmp/disabled-log" "$MOCK_LOG"
"$repo/bin/dim" status | grep -q 'Dim: disabled'
"$repo/bin/dim" --help | grep -q 'Usage: dim'
echo 'Dim CLI checks passed.'
