# Dim for Omarchy

Dim every display with a black overlay, toggle it from the bar, and adjust its strength from the display panel. This bundle includes the `oma.dim` service, the `oma.display` monitor widget, and the `oma.indicators` status widget.


https://github.com/user-attachments/assets/535337ed-982e-4a4e-a2a6-457716df9509



## Install

If upgrading from an earlier install, first disable and remove any old IDs you have installed so their bar widgets and service do not run alongside Dim:

```sh
omarchy plugin disable jarvis.indicators && omarchy plugin remove jarvis.indicators
omarchy plugin disable jarvis.display && omarchy plugin remove jarvis.display
omarchy plugin disable jarvis.dim && omarchy plugin remove jarvis.dim
omarchy plugin disable jarvis.screendim && omarchy plugin remove jarvis.screendim
```

Run only the commands for IDs present on your system. Removing the old service does not remove the saved `screendim` strength setting.

Install the root plugin, then run its companion helper. The helper installs both widgets, rescans Omarchy, enables the service, and enables the cloned widgets. Omarchy replaces each matching built-in in place, keeping its bar position and settings; if a matching built-in is absent, Omarchy uses the widget's normal default placement.

```sh
omarchy plugin add https://github.com/yogeshsuryag/dim.git
"${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/oma.dim/install-companions"
```

If you have already installed the companions and want to replace changed copies, run the helper with `--replace`. It backs up conflicting folders before replacing them.

## Use

- Click the Screen Dim indicator to toggle the overlay.
- Open the Display widget to adjust dim strength, brightness, text size, scaling, and monitor state.
- Call the service over Omarchy IPC:

```sh
omarchy-shell oma.dim toggle
omarchy-shell oma.dim status
omarchy-shell oma.dim setStrength 60
```

Strength is an integer from `0` to `100`; `0` hides the overlay. The overlay starts disabled after a shell restart, while strength is saved under `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/screendim/`.

## Remove

Remove the widgets before removing the service they call:

```sh
omarchy plugin disable oma.indicators
omarchy plugin disable oma.display
omarchy plugin disable oma.dim
omarchy plugin remove oma.indicators
omarchy plugin remove oma.display
omarchy plugin remove oma.dim
```

Removing `oma.dim` does not remove the two companion folders or the saved state directory. Remove those separately if desired.

## License and attribution

The root `oma.dim` plugin is MIT licensed; see [LICENSE](LICENSE). Adapted Omarchy portions in the two companion plugins retain Omarchy's MIT copyright and license notice in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). See [TECHNICAL.md](TECHNICAL.md) for details.
