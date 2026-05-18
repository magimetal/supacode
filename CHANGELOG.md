# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.7] - 2026-05-18

### Added

- Add nested sidebar worktree grouping by branch with onboarding guidance.
- Add pinned and active sidebar highlight sections for relevant worktrees.

### Changed

- Improve sidebar refresh reliability and detail/menu-bar performance with per-tab observation and cached snapshots.
- Move agent presence into reducer-managed state and add per-tab terminal progress indicators.

### Fixed

- Drop the stale `ghostty +list-themes` reference from the terminal theme toggle.
- Preserve fork browser-pane tabs and unsigned local release workflow while syncing upstream main.

## [0.9.6] - 2026-05-15

### Added

- Add hook-driven coding-agent presence and sidebar setup card.
- Add global scripts, per-script color picker, and per-repository Scripts settings from `supacode settings repo`.
- Add Supacode Terminal Theme toggle with glass window tinting.
- Add split terminal File menu actions using Ghostty bindings.
- Persist window position and size across sessions.

### Changed

- Replace toolbar branch button with repo · branch · worktree title.
- Capitalize Supacode consistently in user-facing strings.
- Make the Window-menu Supacode entry shortcut configurable.

### Fixed

- Fix worktree-selection hotkeys for folder repositories and disabled slots.
- Fix sheet dismiss flash after TCA view-side API migration.
- Show quit confirmation only on the main window.

## [0.9.5] - 2026-05-07

### Changed

- Change worktree switch shortcuts to Control-Shift arrow keys and complete PRD-0004 release docs.

## [0.9.4] - 2026-05-06

### Added

- Add terminal tab renaming.
- Add Android Studio as an editor option.

### Changed

- Add unsigned fork release flow documentation and ignore local release artifacts.

### Fixed

- Fix browser focus test determinism.

## [0.9.3] - 2026-04-29

### Fixed

- Fix toolbar Run Script dropdown caching scripts from the first opened repository.

## [0.9.2] - 2026-04-27

### Fixed

- Exclude generated agent instruction docs from app buildable folders to prevent duplicate bundled `AGENTS.md` / `CLAUDE.md` resources.

## [0.9.1] - 2026-04-27

### Added

- Add generated hierarchical `AGENTS.md` project documentation and `CLAUDE.md` compatibility links for agent guidance.

### Changed

- Update repository agent guidance and ignore generated `.trash/` artifacts.

### Fixed

- Fix browser pane hover hit-testing stealing pane focus; browser panes now request focus only for mouse-down events.
