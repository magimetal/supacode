# PRD-0003: Disable Auto-Updates After Fork Divergence

- **Status:** Completed
- **Date:** 2026-04-26
- **Author:** Magi Metal
- **Related:** N/A
- **Supersedes:** N/A

## Problem Statement

This Supacode fork has diverged from upstream releases. Existing Sparkle-based update behavior may check upstream feeds, present update prompts, or download upstream builds that no longer match the local product direction. That creates a risk of confusing users, replacing the forked app with an incompatible upstream release, or encouraging an update path the project no longer supports.

Disable auto-update behavior so the fork remains stable and does not direct users toward upstream releases until a fork-owned update strategy exists.

## User Stories

- As a user of the forked Supacode app, I want the app to avoid automatic update checks so that it does not prompt me to install incompatible upstream builds.
- As a user of the forked Supacode app, I want update controls to be hidden, disabled, or clearly inert so that I do not expect an unsupported update path to work.
- As a maintainer, I want the existing update subsystem neutralized with minimal code churn so that future fork-specific update work remains possible.

## Scope

### In Scope

- Prevent automatic update checks from running during app startup or settings application.
- Prevent automatic update downloads/install flows from being enabled.
- Prevent user-facing update prompts for upstream releases.
- Disable, hide, or make clearly inert update settings/menu controls that initiate checks, choose upstream channels, or configure automatic update behavior.
- Keep the implementation narrowly focused on neutralizing updater behavior for the fork.
- Preserve app build health and existing non-update settings behavior.

### Out of Scope

- Replacing Sparkle with another updater.
- Creating or wiring a fork-specific update feed/server.
- Changing release automation, signing, notarization, or distribution workflows.
- Removing all update architecture or dependencies unless required to safely disable behavior.
- Redesigning the settings UI beyond update-related controls.

## Acceptance Criteria

- [x] Launching the app does not trigger an automatic Sparkle/background update check.
- [x] Applying settings does not enable automatic update checks or automatic update downloads.
- [x] Manual update entry points, including settings controls and any menu action, are hidden, disabled, or clearly inert.
- [x] The app does not present an upstream update prompt during normal use.
- [x] Existing update channel selection cannot cause an upstream background check.
- [x] Non-update settings continue to render and behave normally.
- [x] The app build passes after the updater behavior is disabled.
- [x] The change avoids unrelated updater architecture removal unless necessary for compilation or safety.

## Technical Surface

- **Supacode macOS app:** Swift/TCA application in `supacode/`.
- **Updates reducer:** `supacode/Features/Updates/Reducer/UpdatesFeature.swift` currently applies update settings and dispatches manual checks through `UpdaterClient`.
- **Updater client:** `supacode/Clients/Updates/UpdaterClient.swift` currently owns Sparkle `SPUStandardUpdaterController`, automatic check/download flags, background checks, channel selection, and manual checks.
- **Settings UI:** `supacode/Features/Settings/Views/UpdatesSettingsView.swift` currently exposes channel selection, manual check, and automatic update toggles.
- **Menus/commands:** Any app menu command that sends `.checkForUpdates` should be disabled, hidden, or inert if present.
- **Related ADRs:** N/A. No architecture decision is required for a narrow disablement; create an ADR only if implementation replaces the update strategy or removes Sparkle entirely.

## UX Notes

- Prefer hiding or disabling unsupported update controls over leaving active controls that silently fail.
- If an update settings section remains visible, it should clearly communicate that automatic updates are disabled for this fork.
- Avoid alarming copy; this is a deliberate fork policy, not an error state.
- Do not introduce a new update workflow in this PRD.

## Open Questions

- Should the Updates settings section be removed entirely, or retained with disabled controls and explanatory copy?
- Are there app-menu update commands outside the Settings view that need to be disabled or removed?
- Should Sparkle remain linked but inert, or should a later ADR evaluate removing Sparkle from the app target?

## Completion Notes

- Completed in implementation commit `79de53a` (`Disable automatic updates`).
- Implementation review reported PASS with no remaining required changes.
- Verification recorded for completion: `make test`, `make build-app`, and `make lint` passed in the implementation/review context.

## Revision History

- 2026-04-26: Status changed to Completed; implementation commit `79de53a` disabled automatic updates and review reported PASS.
- 2026-04-26: Status changed to Active; implementation is planned for disabling auto-update behavior.
- 2026-04-26: Draft created for disabling auto-update behavior after fork divergence.
