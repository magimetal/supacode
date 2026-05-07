# PRD-0004: Worktree Switch Hotkey Modifier

- **Status:** Active
- **Date:** 2026-05-06
- **Author:** Magi Metal
- **Related:** N/A
- **Supersedes:** N/A

## Problem Statement

Supacode currently uses plain Control+number shortcuts to switch between worktrees from the sidebar, with the corresponding shortcut hints shown in sidebar rows while a shortcut modifier is held. That conflicts with terminal-heavy workflows because Control is a high-frequency terminal modifier and should remain available for shell, editor, multiplexer, and TUI interactions.

Change direct worktree switching away from plain Control+number while preserving the existing Command+number tab switching behavior and its tab-bar hints.

## User Stories

- As a terminal-heavy Supacode user, I want worktree switching to avoid plain Control+number so that terminal workflows can use Control combinations without unexpected app-level worktree changes.
- As a Supacode user, I want a visible shortcut hint for the new worktree switch chord so that I can discover and remember the replacement shortcut.
- As a Supacode user, I want Command+number tab switching to keep working exactly as before so that worktree shortcut changes do not disrupt terminal tab navigation.
- As a maintainer of the fork, I want the chosen default shortcut to be low-conflict on macOS and shippable in the next fork release.

## Scope

### In Scope

- Change the default direct worktree selection shortcuts from Control+number to Control+Shift+number for worktree slots 1 through 10 (`1` through `9`, then `0`).
- Update sidebar shortcut hints so they display the effective worktree switch shortcut for the chosen modifier chord.
- Ensure sidebar hints do not appear for plain Control alone after the shortcut changes.
- Preserve Command+number tab switching and existing tab-bar shortcut hints.
- Preserve user shortcut override behavior where applicable: custom overrides should continue to determine displayed shortcut text and command shortcut registration.
- Add or update focused tests/verification for shortcut definitions, command registration behavior, and hint gating if the implementation surface supports automated coverage.
- Include the change in the fork release readiness workflow after implementation.

### Out of Scope

- Redesigning the full keyboard shortcut settings UI.
- Adding a runtime setting that lets users choose among Control+Shift, Option/Alt, and Command+Shift as the default chord.
- Changing tab selection shortcuts, Ghostty tab keybindings, terminal tab rendering, or terminal pane behavior.
- Changing worktree ordering, selection semantics, sidebar persistence, command palette behavior, or worktree history navigation outside shortcut registration/hints.
- Editing generated Xcode project/workspace files.
- Mutating vendored `ThirdParty/ghostty` or bundled `Resources/git-wt` content.

## Acceptance Criteria

- [ ] Plain Control+number no longer switches worktrees in the default configuration.
- [ ] Control+Shift+number switches to the corresponding visible sidebar worktree slot for slots 1-10 (`1`-`9`, then `0`).
- [ ] Sidebar shortcut hints show the effective worktree switch shortcuts as `⌃⇧1` through `⌃⇧0` when the worktree hint modifier state is active.
- [ ] Sidebar shortcut hints do not appear when only plain Control is held.
- [ ] Command+number tab switching remains unchanged and continues to switch terminal tabs.
- [ ] Tab-bar shortcut hints remain `⌘1` through `⌘9` and continue to appear while Command is held.
- [ ] Worktree shortcut overrides, if configured, continue to drive both the registered shortcut and the displayed sidebar hint.
- [ ] The implementation avoids introducing conflicts with macOS reserved screenshot shortcuts (`⌘⇧3`, `⌘⇧4`, `⌘⇧5`) or Option-number text input/Meta behavior.
- [ ] Release readiness includes the hotkey change in the fork build/release notes and reports the build as ready for user testing.

## Technical Surface

- **Supacode macOS app:** Swift/TCA application in `supacode/`.
- **Shortcut definitions:** `SupacodeSettingsShared/App/AppShortcuts.swift` defines `selectWorktree1` through `selectWorktree0` and `AppShortcuts.worktreeSelection`.
- **Worktree command registration:** `supacode/Commands/WorktreeCommands.swift` registers direct worktree selection menu shortcuts from `AppShortcuts.worktreeSelection`.
- **Sidebar shortcut hints:** `supacode/Features/Repositories/Views/SidebarItemsView.swift` resolves displayed worktree shortcut hints from effective shortcuts.
- **Shortcut hint modifier observer:** `supacode/App/CommandKeyObserver.swift` currently gates hint visibility on Command or Control modifier state and will need behavior that distinguishes tab hints from the new worktree hint chord.
- **Tab hint behavior:** `supacode/Features/Terminal/TabBar/Views/TerminalTabView.swift` currently displays `⌘number` tab hints and must remain unchanged in behavior.
- **Terminal/Ghostty routing:** `supacode/Infrastructure/Ghostty/` and Ghostty shortcut wiring should be inspected only as needed to confirm no plain Control+number app shortcut remains active for worktree switching.
- **Related ADRs:** N/A. No architecture decision is required for this narrow behavior change; create an ADR only if implementation requires a broader shortcut routing model.

## UX Notes

- Default to Control+Shift+number among the user-approved candidates.
  - Command+Shift+number is rejected as the default because macOS reserves Command+Shift+3/4/5 for screenshots and screen capture UI.
  - Option/Alt+number is rejected as the default because macOS text input can produce alternate characters and terminal users may map Option as Meta/Alt.
  - Control+Shift+number keeps the existing mental model near Control+number while avoiding accidental plain-Control terminal conflicts.
- The hint system should make the active chord explicit. Showing worktree hints for plain Control alone would imply the old shortcut still works and should be avoided.
- Command-held tab hints should continue to feel browser-like and should not be coupled to the worktree hint chord beyond any shared observer implementation.
- If implementation discovers Control+Shift+number is not viable in SwiftUI/AppKit shortcut handling, pause and revisit the default chord before implementation continues.

## Open Questions

- Should release notes describe this as a breaking shortcut change or a terminal-compatibility fix?
- Should any existing user shortcut override persisted as Control+number be migrated, warned about, or left untouched as an explicit user override?

## Revision History

- 2026-05-06: Draft created for changing worktree switching away from plain Control+number.
- 2026-05-06: Moved to Active after implementation plan review passed.
