# Dim for Omarchy

Dim every display with a black overlay. Toggle it from the bar and adjust its strength from the display panel. This bundle includes the `oma.dim` service, the `oma.display` monitor widget, and the `oma.indicators` status widget.

[![Watch the 15-second demo](docs/assets/dim-demo-poster.png)](https://raw.githubusercontent.com/yogeshsuryag/dim/refs/heads/main/docs/assets/dim-demo.mp4)

GitHub does not play video files stored in a repository inline in a README. Click the preview to download the MP4, then open it in a video player.

## Install

Add the plugin, then run its installer:

```sh
omarchy plugin add https://github.com/yogeshsuryag/dim.git
"${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/oma.dim/install"
```

The installer adds the `dim` command and both widgets, rescans Omarchy, and enables all three plugins. If a different `dim` command is already installed, pass `--replace` to back it up before installing this one.

## Use

Use `dim` to toggle dimming, check status, change strength, or enable and disable Dim:

```sh
dim toggle
dim status
dim strength 60
dim enable
dim disable
```

Run `dim` or `dim help` to see the command list. `dim status` shows whether Dim is enabled or dimming and reports its strength. `dim strength` shows the current strength; `dim strength 60` sets it from `0` to `100` while preserving the current on/off state, with `0` hiding the overlay. If `dim toggle` or `dim strength` reports `Dim is disabled. Run: dim enable`, run `dim enable` to enable all three plugins. `dim disable` turns the overlay off and disables the plugins while keeping their files and saved strength. The `dim` command is installed in `~/.local/bin`.

## Remove

Run `dim remove` to disable and remove Dim, its companion widgets, and the `dim` command. Your saved strength setting is retained.

## License and attribution

The root `oma.dim` plugin is MIT licensed; see [LICENSE](LICENSE). Adapted Omarchy portions in the two companion plugins retain Omarchy's MIT copyright and license notice in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). See [TECHNICAL.md](TECHNICAL.md) for details.
