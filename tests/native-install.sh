#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

if [[ ${1:-} != --inside ]]; then
  for tool in bwrap qs git jq rsync omarchy; do
    command -v "$tool" >/dev/null || { echo "Native test requires $tool" >&2; exit 1; }
  done
  test_dir=$(mktemp -d /tmp/dim-native-install.XXXXXX)
  trap 'rm -rf -- "$test_dir"' EXIT
  mkdir -p "$test_dir/config/plugins" "$test_dir/runtime" "$test_dir/omarchy/shell" "$test_dir/bin"
  chmod 700 "$test_dir/runtime"
  cp "$repo/tests/native-shell.qml" "$test_dir/omarchy/shell/shell.qml"
  ln -s /usr/share/omarchy/shell/Commons "$test_dir/omarchy/shell/Commons"
  ln -s /usr/share/omarchy/shell/plugins "$test_dir/omarchy/shell/plugins"
  printf '%s\n' '{"version":1,"keep":"unchanged","plugins":[],"bar":{"layout":{"left":[],"center":[],"right":[{"id":"omarchy.monitor","testSetting":42},{"id":"omarchy.indicators"}]}}}' > "$test_dir/config/shell.json"
  # The actual native commands hardcode HOME/.config/omarchy. Bind just that
  # directory into an isolated mount namespace; HOME and the desktop stay intact.
  bwrap --die-with-parent --ro-bind / / --dev /dev --proc /proc \
    --bind "$test_dir" "$test_dir" \
    --bind "$test_dir/config" "$HOME/.config/omarchy" \
    --setenv DIM_NATIVE_TEST_DIR "$test_dir" \
    --setenv DIM_BIN_DIR "$test_dir/bin" \
    --setenv XDG_RUNTIME_DIR "$test_dir/runtime" \
    --setenv XDG_CONFIG_HOME "$HOME/.config" \
    --setenv WAYLAND_DISPLAY "dim-native-test-$$" \
    --setenv QT_QPA_PLATFORM offscreen \
    --setenv QT_QPA_PLATFORMTHEME "" \
    --setenv OMARCHY_PATH "$test_dir/omarchy" \
    -- "$repo/tests/native-install.sh" --inside
  exit
fi

test_dir=${DIM_NATIVE_TEST_DIR:?}
rsync -a --exclude=.git --exclude=.wiki "$repo/" "$test_dir/source/"
git -C "$test_dir/source" init -q
git -C "$test_dir/source" add .
git -C "$test_dir/source" -c user.name=Dim-test -c user.email=dim-test@example.invalid commit -qm fixture
qs -p "$OMARCHY_PATH/shell" >"$test_dir/shell.log" 2>&1 &
shell_pid=$!
trap 'kill "$shell_pid" 2>/dev/null || true; wait "$shell_pid" 2>/dev/null || true' EXIT
for ((i=0; i<100; i++)); do
  [[ $(omarchy-shell shell ping 2>/dev/null || true) != pong ]] || break
  if ! kill -0 "$shell_pid" 2>/dev/null; then cat "$test_dir/shell.log"; exit 1; fi
  sleep 0.05
done
[[ $(omarchy-shell shell ping) == pong ]]

# This is the README flow: real git add, real validator, real installer, real
# Quickshell registry and native enable commands. No mocked discovery/activation.
if "$test_dir/source/install" >"$test_dir/missing-root.log" 2>&1; then
  echo 'Installer unexpectedly succeeded before plugin add' >&2; exit 1
fi
grep -q 'First install the root plugin' "$test_dir/missing-root.log"
test ! -e "$DIM_BIN_DIR/dim"
omarchy plugin add "$test_dir/source" --yes
"$HOME/.config/omarchy/plugins/oma.dim/install"
for id in oma.dim oma.monitor oma.indicators; do
  test -f "$HOME/.config/omarchy/plugins/$id/manifest.json"
  omarchy plugin validate "$HOME/.config/omarchy/plugins/$id"
done
test -x "$DIM_BIN_DIR/dim"
omarchy plugin list --json | jq -e '[.[] | select(.id | startswith("oma."))] | length == 3 and all(.enabled)' >/dev/null
jq -e '.keep == "unchanged" and .bar.layout.right[0].id == "oma.monitor" and .bar.layout.right[0].testSetting == 42 and .bar.layout.right[1].id == "oma.indicators"' "$HOME/.config/omarchy/shell.json" >/dev/null
omarchy plugin disable oma.indicators
"$DIM_BIN_DIR/dim" enable
jq -e '[.bar.layout[][] | .id] | index("oma.indicators") != null and index("omarchy.indicators") == null' "$HOME/.config/omarchy/shell.json" >/dev/null
cp "$HOME/.config/omarchy/shell.json" "$test_dir/before-repeat.json"
"$HOME/.config/omarchy/plugins/oma.dim/install"
cmp "$test_dir/before-repeat.json" "$HOME/.config/omarchy/shell.json"

# Existing Oma versions must not leave duplicate services or controls enabled.
for id in oma.dim oma.monitor oma.indicators; do omarchy plugin disable "$id"; done
for pair in 'oma.dim oma.screendim' 'oma.monitor oma.display'; do
  read -r current old_id <<<"$pair"
  cp -a "$HOME/.config/omarchy/plugins/$current" "$HOME/.config/omarchy/plugins/$old_id"
  jq --arg id "$old_id" '.id = $id' "$HOME/.config/omarchy/plugins/$old_id/manifest.json" > "$test_dir/old.json"
  cp "$test_dir/old.json" "$HOME/.config/omarchy/plugins/$old_id/manifest.json"
done
jq 'del(.omarchy)' "$HOME/.config/omarchy/plugins/oma.indicators/manifest.json" > "$test_dir/old.json"
cp "$test_dir/old.json" "$HOME/.config/omarchy/plugins/oma.indicators/manifest.json"
omarchy-shell shell rescanPlugins
for ((i=0; i<100; i++)); do
  omarchy plugin list --json | jq -e 'any(.[]; .id == "oma.display")' >/dev/null && break
  sleep 0.05
done
for id in oma.screendim oma.display; do omarchy plugin enable "$id"; done
omarchy plugin enable oma.indicators --before omarchy.indicators
"$HOME/.config/omarchy/plugins/oma.dim/install" --replace
omarchy plugin list --json | jq -e 'all(.[]; if (.id == "oma.screendim" or .id == "oma.display") then (.enabled | not) else true end)' >/dev/null
jq -e '[.bar.layout[][] | .id] | map(select(. == "oma.indicators")) | length == 1' "$HOME/.config/omarchy/shell.json" >/dev/null
jq -e '[.bar.layout[][] | .id] | index("omarchy.indicators") == null and index("oma.monitor") != null' "$HOME/.config/omarchy/shell.json" >/dev/null
echo 'Native install passed: all three plugins installed/enabled; existing settings preserved; repeat install is unchanged.'
