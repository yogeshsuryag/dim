# Jarvis Dim for Omarchy

Dim every display with a black overlay, toggle it from the bar, and adjust its strength from the display panel. This bundle includes the `jarvis.dim` service, the `jarvis.display` monitor widget, and the `jarvis.indicators` status widget.

[▶ Watch demo](https://github.com/yogeshsuryag/dim/blob/main/docs/assets/dim-demo.mp4)

## Install

Install the root plugin, then run its companion helper. The helper installs both widgets, rescans Omarchy, enables the service, and enables the cloned widgets. Omarchy replaces each matching built-in in place, keeping its bar position and settings; if a matching built-in is absent, Omarchy uses the widget's normal default placement.

```sh
omarchy plugin add https://github.com/yogeshsuryag/dim.git
"${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/jarvis.dim/install-companions"
```

If you have already installed the companions and want to replace changed copies, run the helper with `--replace`. It backs up conflicting folders before replacing them.

## Use

- Click the Screen Dim indicator to toggle the overlay.
- Open the Display widget to adjust dim strength, brightness, text size, scaling, and monitor state.
- Call the service over Omarchy IPC:

```sh
omarchy-shell jarvis.dim toggle
omarchy-shell jarvis.dim status
omarchy-shell jarvis.dim setStrength 60
```

Strength is an integer from `0` to `100`; `0` hides the overlay. The overlay starts disabled after a shell restart, while strength is saved under `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/screendim/`.

## Remove

Remove the widgets before removing the service they call:

```sh
omarchy plugin disable jarvis.indicators
omarchy plugin disable jarvis.display
omarchy plugin disable jarvis.dim
omarchy plugin remove jarvis.indicators
omarchy plugin remove jarvis.display
omarchy plugin remove jarvis.dim
```

Removing `jarvis.dim` does not remove the two companion folders or the saved state directory. Remove those separately if desired.

## License and attribution

The root `jarvis.dim` plugin is MIT licensed; see [LICENSE](LICENSE). Adapted Omarchy portions in the two companion plugins retain Omarchy's MIT copyright and license notice in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). See [TECHNICAL.md](TECHNICAL.md) for details.
