# PRD-0001: Embedded Browser Tabs

- **Status:** Completed
- **Date:** 2026-04-26
- **Author:** Magi Metal
- **Related:** [Implementation plan](../plans/embedded-browser-tabs.md), [ADR-0001](../adr/0001-embedded-browser-tabs-with-webkit-surface-model.md)
- **Supersedes:** N/A

## Problem Statement

Supacode users currently work in a tabbed worktree area centered on terminal surfaces. When they need to inspect web output, documentation, local servers, or other browser-visible work, they must switch out of the app to an external browser. That context switch breaks flow and leaves Supacode's existing tab mechanics unable to represent browser-based work.

Embedded browser tabs solve this by adding a browser tab type inside the existing worktree tab area. The MVP should make browser tabs feel native to Supacode's current tab model while avoiding broader split-pane scope until the top-level browser experience is reliable.

## User Stories

- As a Supacode user, I want to open a browser tab in the existing worktree tab area so that web content can live next to my terminal tabs without leaving the app.
- As a Supacode user, I want basic browser controls so that I can load pages, navigate backward and forward, and refresh without reaching for an external browser.
- As a Supacode user, I want browser tabs to use existing tab selection and close behavior so that browser and terminal tabs remain predictable.
- As a Supacode user, I want browser tab titles to reflect loaded pages so that I can identify browser tabs from the tab bar.
- As a Supacode user, I want existing terminal layout restore behavior to remain reliable while browser tab persistence is deferred to a follow-up pass.

## Scope

### In Scope

- Add a top-level browser tab type in the existing worktree tab area.
- Add a command or menu action for creating a new browser tab when a worktree is active.
- Render browser tab content with compact browser chrome containing:
  - URL/search field.
  - Back button.
  - Forward button.
  - Reload/stop behavior.
  - Loading/progress indication if reasonably available in the planned implementation.
- Load URLs from typed input, including full URLs and common domain-like input.
- Update browser tab title from the loaded page title when available, falling back to host/URL or `New Browser`.
- Close browser tabs through the existing tab close mechanics.
- Preserve terminal tab behavior unchanged.
- Keep existing terminal-only layout snapshot restore behavior compatible and unchanged.

### Out of Scope

- Mixed terminal/browser split panes; this is deferred until top-level browser tabs are stable.
- Browser features beyond the MVP controls listed above.
- Reworking Supacode's terminal naming or tab architecture beyond the minimum needed for browser tab kinds.
- Browser tab persistence/restore, including URL/title metadata, tab order across launches, WebKit storage/session restoration, or full browser session state; this is deferred to a follow-up pass after the first implementation is stable.
- Browser find-in-page unless it becomes necessary for keyboard/focus safety during implementation.

## Acceptance Criteria

- [x] A user can create a browser tab from an app command/menu action while a worktree is active.
- [x] The browser tab appears in the existing worktree tab bar with a browser-appropriate icon and an initial `New Browser` title.
- [x] Selecting a browser tab renders browser chrome and a web surface instead of a terminal split surface.
- [x] Typing a URL or domain-like value in the URL field loads the intended page.
- [x] Back, forward, and reload/stop controls update enabled/loading state according to the active page.
- [x] The tab title updates from page title when available, otherwise from host/URL, without breaking terminal title behavior.
- [x] Closing a browser tab uses the existing tab close flow and selects the next appropriate tab.
- [x] Creating, selecting, and closing terminal tabs continues to behave as before.
- [x] Browser tab creation does not create an unintended terminal surface or split tree for that browser tab.
- [x] Legacy terminal-only layout snapshots still restore successfully.
- [x] Browser tabs are not required to persist or restore across app launches in the first implementation pass.
- [x] Browser commands do not steal expected text input behavior from the URL field.

## Completion Evidence

- Completed in commit `936d7c2dc8d1440b63f21d53fa01c7a553825d33` on `main`.
- Verification passed: `make build-app`, `make test`, `make lint`.
- Delivered browser MVP scope: top-level `WKWebView` browser tabs in the worktree tab area; no browser persistence; no mixed terminal/browser splits.

## Technical Surface

- **Supacode macOS app:** Existing Swift/TCA application in `supacode/`.
- **Tab models:** `supacode/Features/Terminal/Models/TerminalTabItem.swift`, `TerminalTabManager.swift`, and `TerminalLayoutSnapshot.swift` need browser-aware tab metadata.
- **Runtime state:** `supacode/Features/Terminal/Models/WorktreeTerminalState.swift` needs browser tab storage and lifecycle handling without creating terminal surfaces for browser tabs.
- **Browser feature surface:** New browser model/view files under `supacode/Features/Browser/` are expected for browser state, URL resolution, WebKit hosting, and tab chrome.
- **Rendering:** `supacode/Features/Terminal/Views/WorktreeTerminalTabsView.swift` and related tab content views need a selected-tab branch for browser content.
- **Commands/focused actions:** App command routing through `supacode/Clients/Terminal/TerminalClient.swift`, `WorktreeTerminalManager.swift`, `AppFeature.swift`, `TerminalCommands.swift` or a browser command file, and `WorktreeDetailView.swift` needs a create-browser-tab path.
- **Persistence:** First-pass implementation should preserve legacy terminal snapshot compatibility only. Browser tab URL/title persistence and mixed terminal/browser restore behavior are deferred follow-up scope.
- **Related ADRs:** [ADR-0001: Embedded Browser Tabs with WebKit Surface Model](../adr/0001-embedded-browser-tabs-with-webkit-surface-model.md).

## UX Notes

- Browser tabs should live in the same top-level tab bar as terminal tabs.
- Browser tabs should be distinguishable with a browser-appropriate icon such as a globe.
- The browser chrome should be compact and subordinate to the work surface, not a full browser product shell.
- Browser tab close behavior should match existing tab close affordances.
- Browser controls should expose help/tooltips where the existing UI style supports them.
- Menu state should follow existing worktree availability behavior: disabled with no active worktree, enabled with an active worktree.
- MVP should preserve keyboard safety: terminal commands should still target terminal tabs, and browser text entry should remain predictable when the URL field is focused.

## Open Questions

- Should the first MVP default typed search terms to a search engine, or should non-URL input be rejected until a search-provider choice exists?
- Should browser cookies/session data use the app default persistent WebKit store for MVP, or should isolation be revisited before marking the PRD Active?
- Should browser tabs be available for all worktree/folder workspace types identically?
- What persistence model should follow-up browser tab restore use for URL/title metadata, tab order, and WebKit session/storage behavior?

## Revision History

- 2026-04-26: Draft created from `docs/plans/embedded-browser-tabs.md`.
- 2026-04-26: Clarified first-pass scope defers browser tab persistence/restore while retaining legacy terminal snapshot restore acceptance.
- 2026-04-26: Marked Active before implementation begins.
- 2026-04-26: Marked Completed after browser MVP delivery in commit `936d7c2dc8d1440b63f21d53fa01c7a553825d33`; verification passed with `make build-app`, `make test`, and `make lint`.
