# Jarvis Omarchy plugins

This repository contains six Omarchy plugins: the root plugin `jarvis.dim` and five source-only companion directories. Omarchy installs one plugin from a repository root manifest, so install the root plugin with its normal Git URL first, then copy the companions with the helper.

```sh
omarchy plugin add <repository-url>
"${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/jarvis.dim/install-companions"
```

The helper validates every companion and only installs files. It does not enable plugins or edit `shell.json`. Identical installed folders are skipped. A different folder with the same ID stops the run; rerun the same helper with `--replace` to first move that folder to a timestamped backup. After copying, rescan the shell and enable only the plugins you use:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable jarvis.dim
omarchy plugin enable jarvis.indicators
omarchy plugin enable jarvis.display
omarchy plugin enable jarvis.workspaces
```

The `jarvis.indicators` ScreenDim indicator sends IPC to `jarvis.dim`. `jarvis.display` and `jarvis.workspaces` customize built-in Omarchy plugins and require the corresponding stock shell services. The optional `jarvis.bar` replaces the whole bar and expects Omarchy's built-in widget/plugin IDs; enable it only if you want that replacement. `jarvis.clock` replaces the stock clock widget when configured; its `setup` script separately downloads verified Caldir binaries and optionally configures Google Calendar. Review that script before running it. The companion helper never runs it.

Omarchy stores enabled plugin IDs in `~/.config/omarchy/shell.json`. For example, add these entries to the existing configuration's `plugins` array to enable the service and companion widgets (preserve any existing IDs):

```json
{
  "plugins": [
    { "id": "jarvis.dim" },
    { "id": "jarvis.indicators" },
    { "id": "jarvis.display" },
    { "id": "jarvis.workspaces" }
  ]
}
```

The root plugin is a native Git checkout, so update it through Omarchy. Companion folders are copied without Git metadata; update them by rerunning the installed helper with `--replace`, which backs up any changed directory before replacing it. Enable, disable, and remove commands still take one ID at a time:

```sh
omarchy plugin enable jarvis.dim
omarchy plugin disable jarvis.dim
omarchy plugin remove jarvis.dim
```

Use those same enable, disable, and remove commands with each companion ID as needed. Update the root plugin with `omarchy plugin update jarvis.dim`; update companions with the installed helper and `--replace`. Removing `jarvis.dim` before `jarvis.indicators` leaves an indicator whose IPC target is absent; disable/remove the indicator first, then the service. The helper does not remove installed companions.

## Source and attribution

The root `jarvis.dim` plugin is MIT licensed; see [LICENSE](LICENSE). Companion source is copied from the installed user plugin directories. Manifest attribution is retained: the clock plugin names Guiestrela; the bar and indicators name Omarchy; display and workspaces name Jarvis. The copied clock source directory contains no license file, so this repository does not claim to relicense that companion under the root MIT license.

## Validate

```sh
omarchy plugin validate .
for id in jarvis.bar jarvis.clock jarvis.display jarvis.indicators jarvis.workspaces; do
  omarchy plugin validate "companions/$id"
done
bash -n install-companions tests/install-companions.sh
./tests/install-companions.sh
```
