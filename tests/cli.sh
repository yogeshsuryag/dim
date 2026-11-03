#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dim-cli-test.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
export DIM_TEST_ROOT=$tmp MOCK_LOG=$tmp/log
export XDG_STATE_HOME=$tmp/state-home
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
  'plugin remove oma.dim') printf 'remove oma.dim\n' >> "$MOCK_LOG"; rm -rf -- "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim"; python3 - "$DIM_TEST_ROOT/plugins.json" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as file: plugins = json.load(file)
with open(path, 'w') as file: json.dump([item for item in plugins if item['id'] != 'oma.dim'], file)
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
  'shell rescanPlugins') ;;
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

# Removal uses isolated config, plugin, state, and command locations.
export XDG_CONFIG_HOME="$DIM_TEST_ROOT/config"
mkdir -p "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim" "$XDG_CONFIG_HOME/omarchy/plugins/oma.display" "$XDG_CONFIG_HOME/omarchy/plugins/oma.indicators" "$DIM_TEST_ROOT/installed-bin"
for id in oma.dim oma.display oma.indicators; do
  printf '{"id":"%s"}\n' "$id" > "$XDG_CONFIG_HOME/omarchy/plugins/$id/manifest.json"
done

# Removal backs up shell config, disables all three ids, removes the root via
# Omarchy's command, removes only the two companion folders, and keeps state.
cp "$repo/bin/dim" "$DIM_TEST_ROOT/installed-bin/dim"
export DIM_BIN_DIR="$DIM_TEST_ROOT/installed-bin"
printf '{"plugins":[]}' > "$XDG_CONFIG_HOME/omarchy/shell.json"
cp "$repo/bin/dim" "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim/bin-dim-source"
mkdir -p "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim/bin"
cp "$repo/bin/dim" "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim/bin/dim"
mkdir -p "${XDG_STATE_HOME:-$DIM_TEST_ROOT/state-home}/omarchy/screendim"
printf '{"strength":42}\n' > "${XDG_STATE_HOME:-$DIM_TEST_ROOT/state-home}/omarchy/screendim/strength.json"
python3 - "$DIM_TEST_ROOT/plugins.json" <<'PY'
import json, sys
plugins = json.load(open(sys.argv[1]))
for plugin in plugins: plugin['enabled'] = True
json.dump(plugins, open(sys.argv[1], 'w'))
PY
# A plugin folder symlink must stop removal before changing Omarchy or its target.
mkdir -p "$DIM_TEST_ROOT/outside"
printf 'keep\n' > "$DIM_TEST_ROOT/outside/keep"
mv "$XDG_CONFIG_HOME/omarchy/plugins/oma.display" "$DIM_TEST_ROOT/display-dir"
ln -s "$DIM_TEST_ROOT/outside" "$XDG_CONFIG_HOME/omarchy/plugins/oma.display"
if "$repo/bin/dim" remove >"$tmp/remove-symlink.out" 2>&1; then
  echo 'symlink plugin directory unexpectedly removed' >&2
  exit 1
fi
grep -q 'refusing symlink plugin directory' "$tmp/remove-symlink.out"
[[ -f "$DIM_TEST_ROOT/outside/keep" ]]
[[ $(python3 -c 'import json,sys; print(str(all(x["enabled"] for x in json.load(open(sys.argv[1])))).lower())' "$DIM_TEST_ROOT/plugins.json") == true ]]
unlink "$XDG_CONFIG_HOME/omarchy/plugins/oma.display"
mv "$DIM_TEST_ROOT/display-dir" "$XDG_CONFIG_HOME/omarchy/plugins/oma.display"
"$DIM_TEST_ROOT/installed-bin/dim" remove >/dev/null
[[ ! -e "$DIM_TEST_ROOT/installed-bin/dim" ]]
[[ ! -e "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim" ]]
[[ ! -e "$XDG_CONFIG_HOME/omarchy/plugins/oma.display" ]]
[[ ! -e "$XDG_CONFIG_HOME/omarchy/plugins/oma.indicators" ]]
[[ -n $(find "$XDG_CONFIG_HOME/omarchy" -maxdepth 1 -name 'shell.json.backup.*' -print -quit) ]]
[[ -f "${XDG_STATE_HOME:-$DIM_TEST_ROOT/state-home}/omarchy/screendim/strength.json" ]]
# Re-running against absent plugin folders is safe and leaves the repo source intact.
"$repo/bin/dim" remove >/dev/null
[[ -f "$repo/bin/dim" ]]
[[ -f "${XDG_STATE_HOME:-$DIM_TEST_ROOT/state-home}/omarchy/screendim/strength.json" ]]
echo 'Dim CLI checks passed.'
