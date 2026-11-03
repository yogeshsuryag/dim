# Jarvis Omarchy plugins

This repository contains exactly three related plugins: root plugin `jarvis.dim`, plus source-only companions `jarvis.display` and `jarvis.indicators`. Omarchy installs the root plugin from the repository manifest; run its installed helper to copy the two companion folders.

```sh
omarchy plugin add https://github.com/yogeshsuryag/dim.git
"${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/jarvis.dim/install-companions"
```

The helper validates both companions and only installs files. It does not enable plugins or edit `shell.json`. Identical installed folders are skipped. A different folder with the same ID stops the run; rerun the same helper with `--replace` to first move that folder to a timestamped backup. After copying, rescan the shell and enable only the plugins you want:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable jarvis.dim
omarchy plugin enable jarvis.indicators
omarchy plugin enable jarvis.display
```

The `jarvis.indicators` ScreenDim indicator sends IPC to `jarvis.dim` and retains the existing `screendim` state directory. `jarvis.display` customizes Omarchy's built-in monitor plugin and expects its stock shell services.

Omarchy stores enabled plugin IDs in `~/.config/omarchy/shell.json`. Add these objects to the existing configuration's `plugins` array to enable all three (preserve any existing IDs):

```json
{
  "plugins": [
    { "id": "jarvis.dim" },
    { "id": "jarvis.indicators" },
    { "id": "jarvis.display" }
  ]
}
```

The root plugin is a native Git checkout, so update it through Omarchy. Companion folders are copied without Git metadata; update them by rerunning the installed helper with `--replace`, which backs up any changed directory before replacing it. Enable, disable, update, and remove each plugin by its own ID:

```sh
omarchy plugin enable jarvis.dim
omarchy plugin disable jarvis.dim
omarchy plugin update jarvis.dim
omarchy plugin remove jarvis.dim
```

Use enable, disable, and remove with `jarvis.display` and `jarvis.indicators` as needed. Removing `jarvis.dim` before `jarvis.indicators` leaves an indicator whose IPC target is absent; disable/remove the indicator first, then the service. The helper does not remove installed companions.

## Source and attribution

The root `jarvis.dim` plugin is MIT licensed; see [LICENSE](LICENSE). Companion source was copied from the installed user plugin directories. The `jarvis.indicators` manifest credits Omarchy; `jarvis.display` credits Jarvis.

## Validate

```sh
omarchy plugin validate .
for id in jarvis.display jarvis.indicators; do
  omarchy plugin validate "companions/$id"
done
bash -n install-companions tests/install-companions.sh
./tests/install-companions.sh
```
