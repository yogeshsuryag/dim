# Jarvis Dim

An Omarchy shell service that toggles a black overlay across connected screens. Its opacity is configurable from 0 to 100 and persists across shell restarts. The overlay starts disabled after a restart.

## Install

Copy this directory to `~/.config/omarchy/plugins/jarvis.dim/`, then validate and enable it:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/jarvis.dim
omarchy plugin enable jarvis.dim
```

The plugin is enabled from Omarchy's shell plugin configuration. Restart the shell if it does not load immediately.

## Use

Use the Omarchy shell IPC commands:

```sh
omarchy-shell jarvis.dim status
omarchy-shell jarvis.dim toggle
omarchy-shell jarvis.dim enable
omarchy-shell jarvis.dim disable
omarchy-shell jarvis.dim setStrength 35
```

`setStrength` accepts a value from 0 to 100. The setting is stored under `${XDG_STATE_HOME:-~/.local/state}/omarchy/screendim/` so existing dim strength settings remain available after upgrading from `jarvis.screendim`.

When adopting this renamed plugin, update callers and plugins that send shell IPC to `jarvis.screendim` (including `jarvis.indicators` ScreenDim) to use `jarvis.dim` instead.

## Remove

Disable and remove the plugin:

```sh
omarchy plugin disable jarvis.dim
omarchy plugin remove jarvis.dim
```

If it was installed by copying the directory manually, disable it and then remove `~/.config/omarchy/plugins/jarvis.dim/`. The saved strength file is retained; remove `${XDG_STATE_HOME:-~/.local/state}/omarchy/screendim/` separately if you also want to delete that setting.

## License

MIT. See [LICENSE](LICENSE).
