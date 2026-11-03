#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/dim-companions-test.XXXXXX")
export XDG_CONFIG_HOME="$test_root/config"
export MOCK_LOG="$test_root/omarchy.log"
mkdir -p "$test_root/bin" "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim"
export PATH="$test_root/bin:$PATH"

cp "$repo/manifest.json" "$repo/Service.qml" "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim/"
cat > "$XDG_CONFIG_HOME/omarchy/shell.json" <<'JSON'
{
  "version": 1,
  "customSetting": "preserve me",
  "plugins": [{ "id": "existing.service", "setting": "keep" }],
  "bar": {
    "position": "top",
    "layout": {
      "left": [{ "id": "omarchy.menu" }],
      "right": [
        { "id": "omarchy.monitor", "brightness": 73 },
        { "id": "omarchy.indicators", "items": ["Dnd"], "alwaysShow": true }
      ]
    }
  }
}
JSON
cp "$XDG_CONFIG_HOME/omarchy/shell.json" "$test_root/original.json"

cat > "$test_root/bin/omarchy" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == plugin && ${2:-} == validate ]]; then
  dir=${3:?plugin directory required}
  id=$(jq -r '.id // empty' "$dir/manifest.json")
  [[ ${FAIL_VALIDATE_ID:-} != "$id" ]] || { echo "mock validation failure: $id" >&2; exit 1; }
  /usr/share/omarchy/bin/omarchy-plugin-validate "$dir"
elif [[ ${1:-} == plugin && ${2:-} == list && ${3:-} == --json ]]; then
  python3 - "$XDG_CONFIG_HOME/omarchy/shell.json" <<'PY'
import json, sys
with open(sys.argv[1]) as file:
    config = json.load(file)
ids = {item.get('id') for item in config.get('plugins', [])}
ids |= {item.get('id') for entries in config.get('bar', {}).get('layout', {}).values() for item in entries}
print(json.dumps([{'id': plugin_id, 'enabled': plugin_id in ids} for plugin_id in ('oma.dim', 'oma.display', 'oma.indicators')]))
PY
elif [[ ${1:-} == plugin && ${2:-} == enable ]]; then
  id=${3:?plugin id required}
  printf 'enable %s\n' "$id" >> "$MOCK_LOG"
  python3 - "$XDG_CONFIG_HOME/omarchy/shell.json" "$XDG_CONFIG_HOME/omarchy/plugins/$id/manifest.json" "$id" <<'PY'
import json, sys
config_path, manifest_path, plugin_id = sys.argv[1:]
with open(config_path) as file:
    config = json.load(file)
with open(manifest_path) as file:
    manifest = json.load(file)
if 'bar-widget' not in manifest.get('kinds', []):
    plugins = config.setdefault('plugins', [])
    if not any(item.get('id') == plugin_id for item in plugins):
        plugins.append({'id': plugin_id})
else:
    clone = manifest.get('omarchy', {}).get('clonedFrom')
    layout = config.setdefault('bar', {}).setdefault('layout', {})
    found = False
    for entries in layout.values():
        for entry in entries:
            if entry.get('id') in (plugin_id, clone):
                entry['id'] = plugin_id
                found = True
    if not found:
        section = manifest.get('barWidget', {}).get('defaultSection', 'center')
        if section not in ('left', 'center', 'right'):
            section = 'center'
        layout.setdefault(section, []).append({'id': plugin_id})
with open(config_path, 'w') as file:
    json.dump(config, file, indent=2)
    file.write('\n')
PY
else
  echo "unsupported mock Omarchy command: $*" >&2
  exit 64
fi
MOCK
cat > "$test_root/bin/omarchy-shell" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ ${1:-} == shell && ${2:-} == rescanPlugins ]] || exit 64
MOCK
chmod +x "$test_root/bin/omarchy" "$test_root/bin/omarchy-shell"

# Validation errors must precede installs, config backups, and activation calls.
if FAIL_VALIDATE_ID=oma.indicators "$repo/install-companions" >"$test_root/validation.out" 2>&1; then
  echo "expected validation failure" >&2
  exit 1
fi
cmp "$test_root/original.json" "$XDG_CONFIG_HOME/omarchy/shell.json"
[[ ! -e "$XDG_CONFIG_HOME/omarchy/plugins/oma.display" ]]
[[ ! -e "$XDG_CONFIG_HOME/omarchy/plugins/oma.indicators" ]]
[[ ! -e "$XDG_CONFIG_HOME/omarchy/shell.json.backup."* ]]
[[ ! -s "$MOCK_LOG" ]]

"$repo/install-companions"
for id in oma.dim oma.indicators oma.display; do
  grep -q "^enable $id$" "$MOCK_LOG"
done
backup=$(find "$XDG_CONFIG_HOME/omarchy" -maxdepth 1 -name 'shell.json.backup.*' -print -quit)
[[ -n "$backup" ]]
cmp "$test_root/original.json" "$backup"
jq -e '.customSetting == "preserve me"
  and any(.plugins[]; .id == "existing.service" and .setting == "keep")
  and any(.plugins[]; .id == "oma.dim")
  and .bar.position == "top"
  and .bar.layout.left[0].id == "omarchy.menu"
  and .bar.layout.right[0].id == "oma.display"
  and .bar.layout.right[0].brightness == 73
  and .bar.layout.right[1].id == "oma.indicators"
  and .bar.layout.right[1].items == ["Dnd"]
  and .bar.layout.right[1].alwaysShow == true' "$XDG_CONFIG_HOME/omarchy/shell.json" >/dev/null

# Clone-aware enabling is idempotent and does not create a second config backup.
cp "$XDG_CONFIG_HOME/omarchy/shell.json" "$test_root/repeat.json"
cp "$MOCK_LOG" "$test_root/repeat-log"
backup_count=$(find "$XDG_CONFIG_HOME/omarchy" -maxdepth 1 -name 'shell.json.backup.*' | wc -l)
"$repo/install-companions"
cmp "$test_root/repeat.json" "$XDG_CONFIG_HOME/omarchy/shell.json"
cmp "$test_root/repeat-log" "$MOCK_LOG"
[[ $(find "$XDG_CONFIG_HOME/omarchy" -maxdepth 1 -name 'shell.json.backup.*' | wc -l) == "$backup_count" ]]

# Conflicts abort before activation; explicit replacement preserves config and backs up the folder.
printf 'local edit\n' > "$XDG_CONFIG_HOME/omarchy/plugins/oma.display/local-only"
cp "$MOCK_LOG" "$test_root/conflict-log"
cp "$XDG_CONFIG_HOME/omarchy/shell.json" "$test_root/conflict-config.json"
if "$repo/install-companions" >"$test_root/conflict.out" 2>&1; then
  echo "expected companion conflict" >&2
  exit 1
fi
cmp "$test_root/conflict-log" "$MOCK_LOG"
cmp "$test_root/conflict-config.json" "$XDG_CONFIG_HOME/omarchy/shell.json"
"$repo/install-companions" --replace
[[ ! -e "$XDG_CONFIG_HOME/omarchy/plugins/oma.display/local-only" ]]
plugin_backup=$(find "$XDG_CONFIG_HOME/omarchy/plugin-backups" -maxdepth 1 -type d -name 'oma.display.backup.*' -print -quit)
[[ -n "$plugin_backup" && -f "$plugin_backup/local-only" ]]
[[ $(find "$XDG_CONFIG_HOME/omarchy" -maxdepth 1 -name 'shell.json.backup.*' | wc -l) == "$backup_count" ]]

# With stock clone slots absent, the mocked native API uses the manifest fallback section.
fresh="$test_root/fresh"
export XDG_CONFIG_HOME="$fresh"
mkdir -p "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim"
cp "$repo/manifest.json" "$repo/Service.qml" "$XDG_CONFIG_HOME/omarchy/plugins/oma.dim/"
printf '{"version":1,"plugins":[],"bar":{"layout":{"left":[{"id":"omarchy.menu"}]}}}\n' > "$XDG_CONFIG_HOME/omarchy/shell.json"
cp "$XDG_CONFIG_HOME/omarchy/shell.json" "$test_root/fresh-original.json"
: > "$MOCK_LOG"
"$repo/install-companions"
jq -e 'any(.plugins[]; .id == "oma.dim")
  and .bar.layout.left[0].id == "omarchy.menu"
  and any(.bar.layout.center[]; .id == "oma.display")
  and any(.bar.layout.center[]; .id == "oma.indicators")' "$XDG_CONFIG_HOME/omarchy/shell.json" >/dev/null
cmp "$test_root/fresh-original.json" "$(find "$XDG_CONFIG_HOME/omarchy" -maxdepth 1 -name 'shell.json.backup.*' -print -quit)"
echo "Companion install and enable checks passed (temporary files: $test_root)."
