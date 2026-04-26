# Disable Auto-Updates After Fork Divergence — Implementation Plan

## Objective

Disable Supacode's current Sparkle/upstream auto-update behavior with minimal repo-owned changes, because this fork has diverged from upstream releases.

The implementation should leave the app buildable and keep future fork-owned update work possible. It should not remove Sparkle or redesign update architecture unless a simple inert configuration cannot preserve build/runtime safety.

## Source Documents

- PRD: `docs/prd/0003-disable-auto-updates-after-fork-divergence.md`
- Caller-provided PRD path `docs/prd/0003-disable-auto-updates.md` was not present; observed repo file is the path above.

## Current Repo Evidence Used

- `supacode/Clients/Updates/UpdaterClient.swift`
  - Creates `SPUStandardUpdaterController(startingUpdater: true, ...)` in the live dependency.
  - `configure` writes Sparkle automatic-check/download flags and may call `checkForUpdatesInBackground()`.
  - `setUpdateChannel` changes `updateCheckInterval` and may call `checkForUpdatesInBackground()` when automatic checks are enabled.
  - `checkForUpdates` calls Sparkle `updater.checkForUpdates()`.
- `supacode/Info.plist`
  - Defines upstream `SUFeedURL`.
  - Sets `SUEnableAutomaticChecks` to `true`.
  - Sets `SUAutomaticallyUpdate` to `true`.
- `supacode/Features/Updates/Reducer/UpdatesFeature.swift`
  - Applies persisted update settings to `UpdaterClient`.
  - Sends manual update checks through `UpdaterClient` and captures `update_checked` analytics.
- `supacode/Features/App/Reducer/AppFeature.swift`
  - On settings changes, sends `.updates(.applySettings(...))` using persisted update channel and automatic-update booleans.
  - Routes command-palette `.checkForUpdates` delegates to `.updates(.checkForUpdates)`.
- `supacode/Features/Settings/Views/UpdatesSettingsView.swift`
  - Exposes channel selection, a manual check button, and automatic update toggles.
- `supacode/Commands/UpdateCommands.swift`
  - Adds the app menu item `Check for Updates...` that sends `.checkForUpdates`.
- `supacode/Features/CommandPalette/Reducer/CommandPaletteFeature.swift`
  - Adds a global `Check for Updates` command-palette item.
- `SupacodeSettingsShared/Models/GlobalSettings.swift`
  - Defaults `updatesAutomaticallyCheckForUpdates` to `true` and `updatesAutomaticallyDownloadUpdates` to `false`.
- Existing tests likely needing updates:
  - `supacodeTests/AppFeatureSettingsChangedTests.swift`
  - `supacodeTests/AppFeatureCommandPaletteTests.swift`
  - `supacodeTests/CommandPaletteFeatureTests.swift`
  - `supacodeTests/SettingsFeatureTests.swift`
  - `supacodeTests/SettingsFilePersistenceTests.swift`

## Recommended Approach

Make updater behavior inert in two layers:

1. **Runtime safety layer:** neutralize the live updater client and update reducer so no automatic or manual Sparkle checks/downloads/prompts can run, even if persisted settings still say automatic checks are enabled.
2. **User-facing layer:** remove or disable update controls/menu/palette entry points so users do not see an unsupported update path.

Keep Sparkle linked for now. Removing the dependency is out of scope unless compilation or runtime behavior proves the inert client still starts Sparkle.

## Tasks

### Task 1 — Disable Sparkle defaults in the app plist

**What**

Change bundled Sparkle defaults so the app does not opt into automatic checks/downloads at launch.

**References**

- `supacode/Info.plist`

**Implementation details**

- Change `SUEnableAutomaticChecks` from `<true/>` to `<false/>`.
- Change `SUAutomaticallyUpdate` from `<true/>` to `<false/>`.
- Leave `SUFeedURL` and `SUPublicEDKey` in place for now unless Task 2 proves Sparkle still contacts the upstream feed despite the inert client. This preserves future fork-owned updater work and avoids broad dependency churn.

**Acceptance criteria**

- The built app's plist no longer declares automatic Sparkle checks or automatic updates enabled.
- Upstream feed/key values are not used by normal app execution after the remaining tasks are complete.

**Guardrails**

- Do not change bundle IDs, signing settings, versioning, or unrelated plist keys.
- Do not remove Sparkle configuration keys unless necessary to prevent checks/prompts.

**Verification**

- Inspect `supacode/Info.plist` and confirm both automatic-update booleans are false.
- Later build verification: `make build-app`.

### Task 2 — Make the live updater client inert

**What**

Prevent any Sparkle controller startup, background check, manual check, or automatic download from being invoked by the live app.

**References**

- `supacode/Clients/Updates/UpdaterClient.swift`
- Tests to add/update in `supacodeTests/UpdatesFeatureTests.swift` or the closest existing update/client test file.

**Implementation details**

- Prefer replacing `UpdaterClient.liveValue` with no-op closures for:
  - `configure`
  - `setUpdateChannel`
  - `checkForUpdates`
- Remove the live `SPUStandardUpdaterController(startingUpdater: true, ...)` construction from normal app startup.
- Keep the `UpdaterClient` dependency shape intact so callers compile unchanged.
- Keep Sparkle dependency/import only if still required by remaining code; if no Sparkle symbols remain in the file, remove the unused import but do not remove the package dependency in this task.

**Acceptance criteria**

- Creating `UpdaterClient.liveValue` does not instantiate/start `SPUStandardUpdaterController`.
- `configure(true, true, true)` is inert and cannot enable automatic checks/downloads.
- `setUpdateChannel(.tip)` is inert and cannot trigger a background check.
- `checkForUpdates()` is inert and cannot present a Sparkle prompt.

**Guardrails**

- Do not delete `UpdaterClient` or broad update feature files.
- Do not replace Sparkle with another updater.
- Do not introduce `as any`, `@ts-ignore`, or equivalent type-error suppression.

**Verification**

- Add/adjust focused tests at reducer/dependency level where feasible.
- Later full verification: `make test` and `make build-app`.

### Task 3 — Force update settings application to disabled values

**What**

Ensure update settings cannot re-enable checks/downloads, even when existing settings files contain `updatesAutomaticallyCheckForUpdates: true` or `updatesAutomaticallyDownloadUpdates: true`.

**References**

- `supacode/Features/Updates/Reducer/UpdatesFeature.swift`
- `supacodeTests/AppFeatureSettingsChangedTests.swift`
- Add `supacodeTests/UpdatesFeatureTests.swift` if no focused update reducer tests exist.

**Implementation details**

- In `.applySettings`, ignore incoming automatic-check/download values for updater configuration and call the client with disabled values, e.g. `configure(false, false, false)`.
- Do not call channel-setting behavior if it can trigger a background check. If retaining the call for state consistency, it must be inert after Task 2.
- In `.checkForUpdates`, either make the action a no-op or keep only non-network local behavior. Prefer no-op to avoid analytics that implies a check occurred.

**Acceptance criteria**

- A test proves `.applySettings(updateChannel: .tip, automaticallyChecks: true, automaticallyDownloads: true)` invokes no background check path and only applies disabled updater configuration, if instrumentation exists.
- A test proves `.checkForUpdates` does not invoke `updaterClient.checkForUpdates`.
- `didConfigureUpdates` behavior remains harmless and deterministic.

**Guardrails**

- Do not alter unrelated app settings propagation.
- Do not make persisted settings migration a prerequisite for runtime safety.

**Verification**

- Focused test command, if available after adding tests: `make test TEST_FILTER=UpdatesFeatureTests` or the repo's supported equivalent.
- Full later verification: `make test`.

### Task 4 — Update settings defaults and persisted-settings behavior minimally

**What**

Make new settings files default to disabled automatic update behavior while preserving decoding compatibility for existing settings files.

**References**

- `SupacodeSettingsShared/Models/GlobalSettings.swift`
- `SupacodeSettingsFeature/Reducer/SettingsFeature.swift`
- `supacodeTests/SettingsFeatureTests.swift`
- `supacodeTests/SettingsFilePersistenceTests.swift`

**Implementation details**

- Change `GlobalSettings.default.updatesAutomaticallyCheckForUpdates` to `false`.
- Keep `updatesAutomaticallyDownloadUpdates` as `false`.
- Do not remove the fields from `GlobalSettings`; retaining them avoids settings-file compatibility churn.
- Consider normalizing `SettingsFeature.State` update booleans to false when initialized/loaded, but only if UI still displays those values. Runtime safety must already be guaranteed by Tasks 2-3.

**Acceptance criteria**

- New default global settings have both update automatic booleans false.
- Existing settings files continue to decode.
- Tests expecting the old default automatic-check value are updated intentionally.

**Guardrails**

- Do not introduce a breaking settings schema migration for this narrow change.
- Do not remove update-channel fields unless required by later fork-owned update strategy.

**Verification**

- Run affected settings tests, then `make test`.

### Task 5 — Make update settings UI clearly disabled/inert

**What**

Remove active update controls from Settings, or replace them with static explanatory copy, so users cannot initiate upstream checks or configure unsupported automatic updates from the settings window.

**References**

- `supacode/Features/Settings/Views/UpdatesSettingsView.swift`
- Optionally `supacode/Features/Settings/Views/SettingsView.swift` if choosing to remove the Updates sidebar entry entirely.

**Implementation details**

Preferred minimal UX:

- Keep the Updates settings page to avoid changing settings navigation structure.
- Replace the picker, manual-check button, and automatic update toggles with a read-only message such as: `Automatic updates are disabled for this fork. Install future builds manually until a fork-owned update channel is available.`
- Do not bind UI controls to `settingsStore.updateChannel` or automatic update booleans in this view.

Alternative acceptable UX:

- Remove the Updates sidebar entry entirely, but only if this does not create selection/fallback issues in `SettingsView`.

**Acceptance criteria**

- Settings no longer presents an enabled `Check for Updates now` button.
- Settings no longer presents enabled automatic-update toggles.
- Settings no longer lets a user switch update channel in a way that can trigger a background check.
- Other settings sections still render normally.

**Guardrails**

- Do not redesign unrelated settings layout.
- Do not remove non-update settings state or persistence.

**Verification**

- Manual app check after implementation: open Settings → Updates and confirm only disabled/informational update UI is present.
- Build verification: `make build-app`.

### Task 6 — Disable app menu and command-palette manual update entry points

**What**

Remove, disable, or make inert all non-settings UI paths that initiate manual update checks.

**References**

- `supacode/Commands/UpdateCommands.swift`
- `supacode/App/supacodeApp.swift` if command registration needs adjustment.
- `supacode/Features/CommandPalette/Reducer/CommandPaletteFeature.swift`
- `supacode/Features/CommandPalette/CommandPaletteItem.swift`
- `SupacodeSettingsShared/App/AppShortcuts.swift` only if shortcut metadata must be hidden from shortcut settings.
- `supacodeTests/AppFeatureCommandPaletteTests.swift`
- `supacodeTests/CommandPaletteFeatureTests.swift`

**Implementation details**

- App menu: prefer disabling or omitting `Check for Updates...` from `UpdateCommands`.
- Command palette: remove the global `Check for Updates` item from `commandPaletteItems(...)`, or leave it only if selecting it is clearly inert and labeled unsupported. Removal is cleaner.
- App reducer: after removing the command-palette item, either remove the `.checkForUpdates` delegate route if no longer used, or leave it harmless after Task 3. Keep changes minimal.
- Shortcuts: if `Check For Updates` remains visible in shortcut settings with `⌘U`, consider hiding/removing only that shortcut entry. If removal causes broad shortcut migration churn, leave metadata but ensure no active UI dispatch path remains.

**Acceptance criteria**

- The app menu no longer offers an active update check.
- The command palette no longer returns a visible `Check for Updates` action in normal queries.
- If any stale dispatch path remains, it is inert and covered by Task 3 tests.

**Guardrails**

- Do not disturb unrelated commands or keyboard shortcuts.
- Do not refactor the command-palette architecture.

**Verification**

- Update command-palette tests to assert the update action is absent, not dispatched.
- Manual app check after implementation: app menu and command palette do not expose active update checks.
- Full later verification: `make test`.

### Task 7 — Final verification and regression checks

**What**

Confirm the update subsystem is disabled while the app still builds and unrelated settings continue to work.

**References**

- `Makefile`
- Modified files from Tasks 1-6.

**Acceptance criteria**

- Launch path cannot start Sparkle automatic checks.
- Settings application cannot enable automatic checks/downloads.
- Manual update controls are hidden, disabled, or inert.
- Existing non-update settings behavior is preserved.
- Build and tests pass.

**Guardrails**

- Do not accept a solution that only hides UI while leaving Sparkle automatic checks enabled.
- Do not accept a solution that only changes plist defaults while persisted settings can re-enable checks.
- Do not remove Sparkle dependency/package references unless the simpler inert-client approach fails.

**Verification**

Run, in this order:

```bash
git diff -- supacode/Info.plist supacode/Clients/Updates/UpdaterClient.swift supacode/Features/Updates/Reducer/UpdatesFeature.swift supacode/Features/Settings/Views/UpdatesSettingsView.swift supacode/Commands/UpdateCommands.swift supacode/Features/CommandPalette SupacodeSettingsShared/Models/GlobalSettings.swift supacodeTests
make test
make build-app
git status --short
```

Manual checks:

- Open Settings → Updates and confirm update controls are absent/disabled with explanatory copy.
- Open the app menu and confirm no active `Check for Updates...` action exists.
- Open the command palette and search `update`; confirm no active update-check action is available.

## Open Risks / Unknowns

- **Observed:** Sparkle is currently started from `UpdaterClient.liveValue`; making that live client no-op should be sufficient to stop checks from app code.
- **Observed:** `Info.plist` currently opts into automatic checks/downloads; those defaults must be changed even if the client is made inert.
- **Inferred:** Removing the command-palette item will require updating tests that currently expect `Check for Updates` to appear or dispatch.
- **Unknown:** Whether Sparkle performs any behavior solely from bundle plist keys before `UpdaterClient.liveValue` is touched. Task 1 plus Task 2 are intended to cover both paths.
- **Unknown:** Whether shortcut settings should hide the `Check For Updates` shortcut. Treat this as optional unless an active user-facing dispatch remains.

## Key Files Likely Needing Changes

- `supacode/Info.plist`
- `supacode/Clients/Updates/UpdaterClient.swift`
- `supacode/Features/Updates/Reducer/UpdatesFeature.swift`
- `supacode/Features/Settings/Views/UpdatesSettingsView.swift`
- `supacode/Commands/UpdateCommands.swift`
- `supacode/Features/CommandPalette/Reducer/CommandPaletteFeature.swift`
- `SupacodeSettingsShared/Models/GlobalSettings.swift`
- Relevant tests under `supacodeTests/`

## Explicit Non-Goals

- Do not remove Sparkle from `Project.swift` unless the inert-client approach cannot prevent checks/prompts.
- Do not implement a fork-owned update feed.
- Do not alter release automation, signing, notarization, or distribution.
- Do not refactor update/settings/command-palette architecture beyond what is required to disable current updater behavior.
