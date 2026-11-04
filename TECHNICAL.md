# Technical notes

This repository packages three related Omarchy plugins under one root plugin checkout:

| ID | Kind | Entry point | Role |
| --- | --- | --- | --- |
| `oma.dim` | `service` | `Service.qml` | Full-screen dim overlay, persistent strength setting, and `oma.dim` IPC target |
| `oma.display` | `bar-widget` | `companions/oma.display/Panel.qml` | Monitor controls and screen-dimming controls, based on the Omarchy monitor plugin |
| `oma.indicators` | `bar-widget` | `companions/oma.indicators/Indicators.qml` | Bar indicator that toggles the dim service |

## Omarchy installation model

Omarchy's marketplace and native `omarchy plugin add` flow expect a repository with a `manifest.json` at its root. Adding this repository installs only the root ID, `oma.dim`, into `~/.config/omarchy/plugins/oma.dim/`. Omarchy does not discover `manifest.json` files nested under that directory as separate plugins. The official marketplace submission checklist also expects one plugin manifest at the repository root.

The root `install-companions` helper handles the two additional IDs. It uses `$HOME/.config/omarchy/plugins`, matching Omarchy’s native plugin commands and runtime registry, validates the root and both companion manifests, checks for conflicting destination folders, stages and validates copies, and then installs the two companion folders. It requests a rescan, waits up to five seconds for all three IDs to be discovered, and calls `omarchy plugin enable` for all three IDs. Rescans are asynchronous, so a single immediate list query is not a reliable discovery check. An unchanged repeat install skips rescanning so it does not unload services or reset active dimming. The display manifest intentionally declares `omarchy.clonedFrom: omarchy.monitor`: it is a replacement for the built-in monitor widget, so native enabling preserves the existing position/settings and restores that widget on removal. The indicator is an independent published widget with its own ID and placement immediately before `omarchy.indicators` (center fallback when that widget is absent), so it never inherits unsupported stock-indicator selections or replaces the other indicators. If the matching built-in has no configured slot, Omarchy uses the plugin's native default placement. The helper backs up the current `shell.json` before activation when changes are needed. With `--replace`, a different existing companion folder is moved to a timestamped backup before the replacement is installed.

The helper does not edit `shell.json` directly. It uses Omarchy's plugin command, leaving the shell to persist enabled IDs and bar layout. The repository installer installs the CLI and runs this helper to install or refresh the companion directories and activate all three IDs.

`dim remove` first turns the overlay off and disables each installed ID through Omarchy. It backs up `shell.json`, asks Omarchy to remove the root Git checkout, removes only the two validated companion directories under the configured plugin directory, and deletes the command from the configured user bin only when it is an identical regular-file copy of this CLI. It retains the `screendim` strength state and all backups. Missing plugin directories are allowed, so removal can finish after a partial install.

Omarchy's official `plugin add` command installs plugin files but does not run plugin hooks or export executable commands. The repository installer handles the separate CLI installation and companion setup.

## Legacy IDs

The earlier IDs were `jarvis.dim`, `jarvis.display`, and `jarvis.indicators`; an earlier single-plugin version used `jarvis.screendim`. Omarchy does not automatically replace a third-party widget when a differently named plugin is enabled, so the installer disables any active legacy IDs before enabling the current set. Native widget disabling restores the stock slot first, and the new display control then replaces that slot. Legacy source folders are retained; unrelated plugins are left alone. This avoids duplicate services and bar widgets. The saved strength remains under `omarchy/screendim` and is reused by `oma.dim`. The overlay layer namespace changed from `jarvis-dim` to `oma-dim`; update custom Hyprland rules that match the old namespace.

As of the 2026-11-04 registry search, exact searches for `oma.dim`, `oma.display`, and `oma.indicators` returned no indexed marketplace matches, and the local Omarchy catalog had no `oma.*` IDs. The official rules reserve `omarchy.*`, not `oma.*`, but require IDs to be globally unique and permanent. This older lookup is superseded by the complete catalog/retired-ID check noted below; marketplace approval is still separate.

## Runtime behavior

`Service.qml` implements a Quickshell service and registers an `IpcHandler` with target `oma.dim`. Its methods are:

| Method | Behavior |
| --- | --- |
| `status()` | Returns JSON with `enabled` and `strength` |
| `enable()` | Shows the overlay |
| `disable()` | Hides the overlay |
| `toggle()` | Flips the enabled state and returns `enabled` or `disabled` |
| `setStrength(value)` | Rounds and clamps the value to 0–100, persists it, and returns the resulting integer as text |

Examples using Omarchy's IPC wrapper:

```sh
omarchy-shell oma.dim toggle
omarchy-shell oma.dim status
omarchy-shell oma.dim setStrength 60
```

Each connected display receives a full-screen transparent `PanelWindow` on the overlay layer. A black rectangle inside it uses `strength / 100` opacity. Strength `0` makes the overlay invisible. Dimming is intentionally reset to off when the shell process restarts; strength is retained.

State files live under `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/screendim/`: `active.json` stores the enabled flag, and `strength.json` stores the strength. The existing `screendim` directory name is retained for compatibility. Writes use Quickshell `FileView` with atomic writes.

The display companion clones Omarchy's `omarchy.monitor` identity and UI conventions. It reads and writes the same dim state files and provides brightness, text-size, scale, and monitor controls through the Omarchy shell's existing services. Keep the standard Omarchy bar active for the full built-in service integration expected by the clone.

The indicators companion adapts Omarchy indicator UI code but is registered independently as `oma.indicators`; it contributes the ScreenDim indicator without replacing stock indicators. It uses the stock indicator behavior: active entries remain visible, inactive entries reveal on hover, and `alwaysShow` remains an optional per-instance setting. Both the installer and `dim enable` place it immediately before the stock indicators when those are present. That indicator calls the `oma.dim` IPC target; install and enable the service for the control to work. Its manifest allows multiple widget instances and offers per-instance indicator settings.

## Manifest contract

All three manifests use Omarchy schema version `1`. Required fields include `schemaVersion`, globally unique namespaced `id`, `name`, `version`, `author`, `description`, `kinds`, and `entryPoints`. The entry point key must match the declared kind: `service` for `oma.dim` and `barWidget` for each `bar-widget` companion. Bar widgets also declare display metadata in `barWidget`.

The service manifest at the repository root is the marketplace listing manifest. The companion manifests are validated by the helper as independent plugin folders after they are copied into Omarchy's user plugin directory.

## Validation and tests

The repository includes `tests/install-companions.sh`, an isolated shell-level test for the helper's install, repeat-run, conflict, and replacement behavior. The documented local checks are:

```sh
omarchy plugin validate .
omarchy plugin validate companions/oma.display
omarchy plugin validate companions/oma.indicators
bash -n install install-companions bin/dim tests/*.sh
./tests/cli.sh
./tests/install-companions.sh
./tests/native-install.sh
```

The Omarchy validator checks manifest schema and required fields, reserved IDs, entry-point mappings and paths, file existence, and symlinks. The focused shell tests use isolated fixtures. `tests/native-install.sh` goes further: it runs the documented add/install flow using real Git cloning, Omarchy commands, manifest validation, IPC and the installed `PluginRegistry.qml`. Bubblewrap binds a disposable configuration at the native Omarchy path without changing HOME or touching the real desktop. It checks fresh install, repeat runs, preservation of stock settings, asynchronous discovery, and migration from legacy Dim IDs. It needs `bwrap`, `qs`, `rsync`, Git and the installed Omarchy runtime; it does not load desktop windows, so live QML/IPC checks are still separate.

## Attribution and licensing

The root `oma.dim` plugin is licensed under MIT; its copyright holder is shown in [LICENSE](LICENSE). Portions of both companion directories are adapted from Omarchy source. Their manifests retain attribution metadata: `oma.display` names Dim and records `omarchy.monitor` as its clone source, while `oma.indicators` credits its adaptation from Omarchy without claiming a built-in IPC target or clone identity. The adapted Omarchy portions are under Omarchy's MIT license; the full copyright and license notice, and its scope, are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The root license remains separately scoped and does not replace the Omarchy notice.

## Marketplace listing and verification

Official references:

- [Publish a plugin](https://plugins.omarchy.org/publish.html)
- [Develop a custom plugin](https://plugins.omarchy.org/develop.html)
- [Omarchy shell plugin manual](https://github.com/omacom/omarchy/blob/quattro/manual/32-shell-plugins.md)
- [Omarchy shell manifest and IPC reference](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md)
- [Marketplace submission instructions](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md)
- [Marketplace verification policy](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/VERIFICATION.md)

The marketplace asks for a public GitHub repository, a valid root manifest, a root README and license, and safe installation and removal instructions. A preview image is optional. The structured submission asks for the repository URL, one category, and one to three supported tags. The submission checklist also asks the submitter to confirm permission to submit the work and preview assets, document dependencies and licensing, avoid overwriting user configuration without consent, and acknowledge that listing approval is not a security review.

The submission form is [here](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml). It has not been submitted for this repository.

The marketplace's new-listing workflow validates the repository and scans the exact validated commit without running plugin code. A maintainer applies the `approved-and-verified` label after the bot's current reports are available; publication follows a matching fresh scan. A passing automated baseline can result in a verified snapshot. A selective `review-required` result needs an exact-evidence maintainer attestation; blocking findings or scan failures prevent publication.

“Verified” applies to the exact marketplace snapshot commit and means the eligible automated baseline passed or an authorized maintainer reviewed the reported capabilities/findings for that commit. It is not a security audit, certification, warranty, endorsement, or guarantee that code is safe. If the upstream branch advances, the newer code is unverified until separately checked and published. Omarchy's normal `plugin add` command installs mutable current upstream and is not bound to the marketplace's verified SHA, so users should inspect the installed commit before enabling it.

## Scope

This repository intentionally contains only `oma.dim`, `oma.display`, and `oma.indicators`. The root manifest makes `oma.dim` the single root plugin listing candidate; the companion plugin manifests remain part of the bundled source and are installed by the helper.

## Publishing readiness (2026-11-05)

The repository has one root listing manifest, a README with the required two-step install and CLI removal, and a root MIT license plus upstream MIT notices. Companion manifests remain two directory levels below the root and are installed explicitly, not through unsupported install hooks. All IDs, QML module names and IPC targets use their own non-reserved namespaces. The display retains intentional replacement metadata; the independent indicator does not retain temporary clone metadata. Omarchy’s native commands scan `$HOME/.config/omarchy` rather than an XDG_CONFIG_HOME override; the installer and CLI follow that same location.

The authoritative marketplace registry was checked on 2026-11-05: none of the 6,271 published catalog entries or the retired IDs matched `oma.dim`, `oma.display`, or `oma.indicators`. This is a point-in-time collision check, not a reservation or marketplace approval. Listing and commit-bound verification still require the official submission/review process. The bundled companion installation and user-level CLI/config changes must be disclosed as manual setup.
