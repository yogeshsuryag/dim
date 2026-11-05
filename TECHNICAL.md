# Technical notes

## Source and scope

Version 1.1.0 copies the installed `jarvis.screendim`, `jarvis.indicators`, and `jarvis.display` implementations captured on 2026-11-06. QML/JavaScript behavior is unchanged. The substitutions are:

| Source | Published copy | Entry point |
| --- | --- | --- |
| `jarvis.screendim` | `oma.screendim` | `Service.qml` |
| `jarvis.indicators` | `oma.indicators` | `companions/oma.indicators/Indicators.qml` |
| `jarvis.display` | `oma.monitor` | `companions/oma.monitor/Panel.qml` |

Jarvis helper types become Oma helper types; widget module names and IPC targets become `oma.indicators` and `oma.monitor`. The service target and overlay namespace become `oma.screendim` and `oma-screendim`. The existing `omarchy/screendim` state paths are retained. Manifest changes are limited to identity, author attribution, version, MIT licensing, and default placement. Both widgets retain their original `omarchy.clonedFrom` values so native enabling replaces the stock widgets and disabling restores them.

The Indicators copy includes all eight original indicators and all three local helper types. The Monitor copy includes its original `Model.js`. Neither depends on an installed Jarvis plugin.

## Packaging and marketplace conventions

The marketplace submission uses one root manifest, `oma.screendim`, with a root README and MIT license. Companion manifests remain nested source folders, installed separately by the manual installer. Omarchy's native `plugin add` discovers only the root plugin; it does not execute installation hooks or install the command. The marketplace listing must disclose manual setup and the two companion IDs.

All manifests use schema version 1 and namespaced IDs outside reserved `omarchy.*`. Service and bar-widget entry points use `service` and `barWidget` respectively. Entry points are relative paths to regular files; no symlinks are included. The complete upstream MIT notice is retained in `THIRD_PARTY_NOTICES.md`.

Official references: [submission instructions](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md), [publishing guide](https://plugins.omarchy.org/publish.html), [verification policy](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/VERIFICATION.md).

The existing [submission #13896](https://github.com/omacom/omarchy-plugin-marketplace/issues/13896) previously described version 1.0.2 (`oma.dim`). This revision changes the requested root ID to `oma.screendim` and the monitor ID to `oma.monitor`; it replaces the former Screen Dim-only indicator with the full Jarvis Indicators copy. This is an update to the pending submission. Marketplace review and exact-commit verification remain separate from local validation.

## Installation and migration

`install` validates all source plugins, installs the CLI, and invokes `install-companions`. The helper validates and stages both companion folders before replacing any files, rejects conflicts unless `--replace` was passed, backs up replaced folders, rescans and waits for discovery, backs up the shell configuration, disables known legacy IDs, and enables the new set through native commands. Identical repeat installs avoid rescanning and configuration changes.

Legacy IDs are `jarvis.dim`, `jarvis.screendim`, `jarvis.display`, `jarvis.indicators`, `oma.dim`, and `oma.display`. Their files remain intact. The indicators ID is unchanged from the previous public bundle, so upgrading its different source requires `install --replace`. Previous root checkouts can remain disabled beside the new root checkout. Custom IPC callers and Hyprland rules must use the new targets and namespace.

The helper follows Omarchy's native `$HOME/.config/omarchy/plugins` location. The command is installed in `${DIM_BIN_DIR:-${XDG_BIN_HOME:-$HOME/.local/bin}}`. Removal validates paths, refuses symlinks, backs up shell configuration, turns the overlay off, disables plugins, removes the root checkout with native Omarchy removal, deletes validated companion folders, and removes the installed CLI only when it matches the bundled command. State and backups remain.

## Validation

```sh
omarchy plugin validate .
omarchy plugin validate companions/oma.monitor
omarchy plugin validate companions/oma.indicators
bash -n install install-companions bin/dim tests/*.sh
./tests/cli.sh
./tests/install-companions.sh
./tests/native-install.sh
```

The shell tests check command behavior, validation failures, discovery timeout, conflict handling, replacement backups, settings preservation, and repeat installs. The native test runs real Git cloning, the installed Omarchy validator, native commands, and the Quickshell plugin registry inside Bubblewrap with isolated config. It requires `bwrap`, `qs`, `rsync`, Git, `jq`, and Omarchy. It verifies both widgets replace the stock entries and legacy plugins are disabled. These tests do not verify live overlay rendering or hardware monitor controls.
