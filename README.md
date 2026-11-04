# Dim for Omarchy

Dim every display with a black overlay. Toggle it from the bar and adjust its strength from the display panel. This bundle includes the `oma.dim` service, the `oma.display` monitor widget, and the `oma.indicators` status widget.

[![Play the 15-second demo](docs/assets/dim-demo-poster.png)](https://yogeshsuryag.github.io/dim/)

Click the preview to open the video player.

## Install

Run **both commands**. Omarchy's first command adds only `oma.dim`; the second installs the CLI and both companion widgets, then enables the complete set:

```sh
omarchy plugin add https://github.com/yogeshsuryag/dim.git
"$HOME/.config/omarchy/plugins/oma.dim/install"
```

Wait for `Installed and enabled: oma.dim, oma.display, oma.indicators.` before using Dim. The installer backs up your shell configuration, replaces the stock display control in its existing position, and adds `oma.indicators` immediately to the left of `omarchy.indicators` without removing the other indicators. Like the stock widget, it shows active indicators and reveals inactive ones on hover. Earlier Dim IDs are disabled automatically; their files and saved strength are retained.

Requires Omarchy Quattro with a running shell. The installer uses its existing `omarchy`, `omarchy-shell`, Bash, Git, `jq`, coreutils, and diffutils commands. No sudo is required. Installation changes only your user plugin directories, bar configuration, and `~/.local/bin/dim`.

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
