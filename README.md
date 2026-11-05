# Dim for Omarchy

The current Jarvis screen-dimming setup, copied with the Oma names:

- `jarvis.screendim` → `oma.screendim`: adjustable black overlay on every display.
- `jarvis.indicators` → `oma.indicators`: the complete indicator widget, including Screen Dim, Night Light, Do Not Disturb, Stay Awake, Reminder, Screen Recording, Remote Session, and Passwordless Sudo.
- `jarvis.display` → `oma.monitor`: brightness, text size, scale, monitor, and screen-dimming controls.

The QML and JavaScript implementations retain the Jarvis behavior. Changes are limited to names, module/IPC identities, and publishing metadata. Both widgets retain their stock replacement metadata: Monitor replaces `omarchy.monitor` and Indicators replaces `omarchy.indicators`, preserving their configured positions and settings.

[![Play the demo](docs/assets/dim-demo-poster.png)](https://yogeshsuryag.github.io/dim/)

The demo shows the earlier Dim version; the current bundle includes the complete Indicators widget.

## Install

Requires Omarchy Quattro and its running standard shell, Bash, Git, `jq`, coreutils, and diffutils. No sudo or additional packages are required on a standard Omarchy installation.

Run both commands:

```sh
omarchy plugin add https://github.com/yogeshsuryag/dim.git
"$HOME/.config/omarchy/plugins/oma.screendim/install"
```

The native add command installs the root service. The manual installer installs both companion plugins and `~/.local/bin/dim`, backs up `shell.json`, and enables the three plugins through Omarchy's native commands. Running it explicitly authorizes replacing the stock Monitor and Indicators widgets. Other widgets and settings are retained. Known earlier Dim/Jarvis IDs are disabled; their files and saved strength are retained.

If an existing companion or `dim` command differs, the installer stops. Use `install --replace` to back it up and replace it. Repeat installation of identical files leaves the configuration unchanged.

## Use

Click Screen Dim in Indicators to toggle the overlay. Adjust its strength in Monitor, or use:

```sh
dim toggle
dim status
dim strength 60
dim enable
dim disable
```

Strength ranges from 0 to 100; 0 hides the overlay. Dimming starts off after a shell restart; strength is retained in `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/screendim/`. `dim disable` turns dimming off and disables all three plugins while retaining their files and saved strength. Native IPC uses `omarchy-shell oma.screendim toggle` (also `status`, `enable`, `disable`, and `setStrength 60`).

## Remove

Run `dim remove` to disable and remove all three plugins and the installed command. Native disabling restores the stock widgets. Saved strength and backups are retained. After a partial installation, the command can be run from the checkout as `bin/dim remove`.

## License

MIT; see [LICENSE](LICENSE) and the upstream Omarchy attribution in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). See [TECHNICAL.md](TECHNICAL.md) for packaging and validation details.
