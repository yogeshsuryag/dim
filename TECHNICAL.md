# Technical notes

This repository packages three related Omarchy plugins under one root plugin checkout:

| ID | Kind | Entry point | Role |
| --- | --- | --- | --- |
| `oma.dim` | `service` | `Service.qml` | Full-screen dim overlay, persistent strength setting, and `oma.dim` IPC target |
| `oma.display` | `bar-widget` | `companions/oma.display/Panel.qml` | Monitor controls and screen-dimming controls, based on the Omarchy monitor plugin |
| `oma.indicators` | `bar-widget` | `companions/oma.indicators/Indicators.qml` | Bar indicator that toggles the dim service |

## Omarchy installation model

Omarchy's marketplace and native `omarchy plugin add` flow expect a repository with a `manifest.json` at its root. Adding this repository installs only the root ID, `oma.dim`, into `~/.config/omarchy/plugins/oma.dim/`. Omarchy does not discover `manifest.json` files nested under that directory as separate plugins. The official marketplace submission checklist also expects one plugin manifest at the repository root.

The root `install-companions` helper handles the two additional IDs. It resolves the plugin directory using `XDG_CONFIG_HOME` (falling back to `$HOME/.config`), validates the root and both companion manifests, checks for conflicting destination folders, stages and validates copies, and then installs the two companion folders. It rescans Omarchy and calls `omarchy plugin enable` for all three IDs. For the two manifests that declare `omarchy.clonedFrom`, Omarchy's clone-aware enable path switches the matching built-in widget to the companion while preserving its existing bar position and settings. If the matching built-in has no configured slot, Omarchy uses the plugin's native default placement. The helper backs up the current `shell.json` before activation when changes are needed. With `--replace`, a different existing companion folder is moved to a timestamped backup before the replacement is installed.

The helper does not edit `shell.json` directly. It uses Omarchy's plugin command, leaving the shell to persist enabled IDs and bar layout. The standard update command updates the root checkout; companions have no Git metadata and are refreshed by rerunning the installed helper with `--replace`.

## Upgrading from the previous IDs

The earlier IDs were `jarvis.dim`, `jarvis.display`, and `jarvis.indicators`; an earlier single-plugin version used `jarvis.screendim`. Omarchy does not automatically replace a third-party widget when a differently named plugin is enabled, so disable and remove any of those IDs that are present before installing `oma.dim`. This avoids duplicate services and bar widgets. The saved strength remains under `omarchy/screendim` and is reused by `oma.dim`. The overlay layer namespace changed from `jarvis-dim` to `oma-dim`; update custom Hyprland rules that match the old namespace.

As of the 2026-11-04 registry search, exact searches for `oma.dim`, `oma.display`, and `oma.indicators` returned no indexed marketplace matches, and the local Omarchy catalog had no `oma.*` IDs. The official rules reserve `omarchy.*`, not `oma.*`, but require IDs to be globally unique and permanent. Marketplace catalog data was not available for a direct exhaustive lookup in this environment; uniqueness must be confirmed by the marketplace when submitting these IDs.

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

The indicators companion clones `omarchy.indicators` and contributes the ScreenDim indicator. That indicator calls the `oma.dim` IPC target; install and enable the service for the control to work. Its manifest allows multiple widget instances and offers per-instance indicator settings.

## Manifest contract

All three manifests use Omarchy schema version `1`. Required fields include `schemaVersion`, globally unique namespaced `id`, `name`, `version`, `author`, `description`, `kinds`, and `entryPoints`. The entry point key must match the declared kind: `service` for `oma.dim` and `barWidget` for each `bar-widget` companion. Bar widgets also declare display metadata in `barWidget`.

The service manifest at the repository root is the marketplace listing manifest. The companion manifests are validated by the helper as independent plugin folders after they are copied into Omarchy's user plugin directory.

## Validation and tests

The repository includes `tests/install-companions.sh`, an isolated shell-level test for the helper's install, repeat-run, conflict, and replacement behavior. The documented local checks are:

```sh
omarchy plugin validate .
omarchy plugin validate companions/oma.display
omarchy plugin validate companions/oma.indicators
bash -n install-companions tests/install-companions.sh
./tests/install-companions.sh
```

The Omarchy validator checks manifest schema and required fields, reserved IDs, entry-point mappings and paths, file existence, and symlinks. The shell test exercises the install helper using stubs rather than modifying a live Omarchy configuration.

## Attribution and licensing

The root `oma.dim` plugin is licensed under MIT; its copyright holder is shown in [LICENSE](LICENSE). Portions of both companion directories are adapted from Omarchy source. Their manifests retain attribution metadata: `oma.display` names Dim and records `omarchy.monitor` as its clone source, while `oma.indicators` names Omarchy and records `omarchy.indicators` as its clone source. The adapted Omarchy portions are under Omarchy's MIT license; the full copyright and license notice, and its scope, are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The root license remains separately scoped and does not replace the Omarchy notice.

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
