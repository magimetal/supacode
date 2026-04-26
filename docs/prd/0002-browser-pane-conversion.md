# PRD-0002: Browser Pane Conversion

- **Status:** Completed
- **Date:** 2026-04-26
- **Author:** Magi Metal
- **Related:** [PRD-0001](./0001-embedded-browser-tabs.md), [ADR-0001](../adr/0001-embedded-browser-tabs-with-webkit-surface-model.md), [ADR-0002](../adr/0002-browser-panes-in-mixed-split-layouts.md)
- **Supersedes:** N/A

## Problem Statement

Supacode now supports embedded browser tabs, but browser and terminal work still live in separate top-level tabs. Users who are running commands and inspecting web output, local servers, docs, or browser-visible app behavior need terminal and browser surfaces side-by-side in the same work area. Switching between top-level tabs breaks the workflow the embedded browser was meant to keep inside Supacode.

Browser pane conversion solves this by letting a user right-click an active terminal pane, split, or tab surface and replace that terminal pane with an embedded browser pane inside the current split layout. The MVP should deliver mixed terminal/browser panes within one tab while preserving existing terminal split behavior and avoiding broader browser product scope.

## User Stories

- As a Supacode user, I want to convert a right-clicked terminal pane into a browser pane so that I can view web content beside my terminal output.
- As a Supacode user, I want the conversion action in the pane right-click menu so that it is discoverable from the surface I am changing.
- As a Supacode user, I want browser panes to coexist with terminal panes in the same split layout so that I can keep terminal and browser context visible at the same time.
- As a Supacode user, I want existing terminal panes, tabs, and split behavior to continue working so that converting one pane does not destabilize the rest of my session.

## Scope

### In Scope

- Add a context menu entry on terminal pane/split surfaces for converting the right-clicked active terminal pane to a browser pane.
- Replace the selected terminal pane leaf in the current split layout with an embedded browser pane.
- Render terminal and browser panes side-by-side within the same top-level tab when the current split layout contains both surface types.
- Reuse the existing embedded browser surface capabilities from PRD-0001 where practical, including basic browser chrome, URL loading, page title behavior, and WebKit rendering.
- Preserve existing terminal pane behavior for panes that are not converted.
- Preserve existing split layout interactions that remain terminal-only or mixed terminal/browser within the MVP scope.
- Keep the MVP focused on the user-requested conversion flow rather than introducing full browser workspace management.

### Out of Scope

- Browser pane persistence or restore across app launches; first-pass mixed pane state may be runtime-only unless implementation requires compatible snapshot handling for terminal safety.
- Mixed terminal/browser drag-and-drop, detachable panes, or generalized surface rearrangement beyond the existing split layout mechanics.
- cmux-scale browser extras, including profiles, proxy controls, history suggestions, storage inspector, importers, or advanced session management.
- DevTools UI beyond any platform-default behavior already available in the existing browser implementation.
- Find-in-page, browser-specific keyboard command suites, or browser command palettes unless required for safe MVP interaction.
- Broad `Terminal*` feature renames or unrelated surface architecture cleanup unless a separate ADR/implementation plan approves that work.

## Acceptance Criteria

- [x] Right-clicking a terminal pane exposes a clearly labeled action to convert that pane to a browser pane.
- [x] Invoking the action replaces the right-clicked terminal pane with an embedded browser pane in the same split position.
- [x] Existing sibling terminal panes remain visible and usable after conversion.
- [x] A mixed split layout can show at least one terminal pane and one browser pane side-by-side within the same top-level tab.
- [x] The converted browser pane supports MVP browser loading and navigation behavior consistent with PRD-0001 where applicable.
- [x] Converting one pane does not create an unintended top-level browser tab.
- [x] Converting one pane does not create an unintended new terminal surface for the browser pane.
- [x] Terminal-only tabs, terminal split creation, terminal focus, and terminal input behavior continue to work as before.
- [x] The context menu action is unavailable, hidden, or safely disabled where conversion is not valid.
- [x] Browser pane conversion does not require browser pane persistence/restore in the MVP.

## Completion Evidence

- Completed on `main` across commits `1dbb8d8` (implementation), `973bc81` (browser pane focus selection), and `4562e0a` (blocker fixes).
- Verification passed: `make test`, `make build-app`, and `make lint`.
- Delivered browser pane conversion MVP scope: right-click terminal pane conversion to browser pane, mixed terminal/browser split leaves, browser chrome/navigation reuse from PRD-0001, no unintended top-level browser tab or placeholder terminal surface, and no browser pane persistence requirement.
- ADR verification: [ADR-0002](../adr/0002-browser-panes-in-mixed-split-layouts.md) remains aligned with the implemented heterogeneous terminal/browser split-leaf approach.

## Technical Surface

- **Supacode macOS app:** Existing Swift/TCA application in `supacode/`.
- **Terminal/worktree split surface:** Current split layout types and views that assume terminal leaves need a mixed surface representation capable of hosting terminal or browser content in a leaf.
- **Context menus:** Terminal pane right-click/context menu code needs a conversion command routed to the right-clicked pane identity, not merely the currently focused pane if those differ.
- **Browser feature surface:** Existing browser state and WebKit view code from PRD-0001 should be reused where possible for browser pane content.
- **Runtime state:** Worktree/tab state needs to replace one terminal leaf with one browser leaf without disturbing sibling leaves or unrelated top-level tabs.
- **Persistence:** MVP should avoid promising browser pane persistence, while preserving existing terminal layout compatibility and preventing mixed runtime state from corrupting terminal restore paths.
- **Related ADRs:** [ADR-0001: Embedded Browser Tabs with WebKit Surface Model](../adr/0001-embedded-browser-tabs-with-webkit-surface-model.md), [ADR-0002: Browser Panes in Mixed Split Layouts](../adr/0002-browser-panes-in-mixed-split-layouts.md). ADR-0002 records the mixed terminal/browser split-leaf architecture for this PRD.

## UX Notes

- The primary entry point should be the right-click context menu on a terminal pane/split surface.
- Suggested menu label: `Convert Pane to Browser` or equivalent concise wording that makes replacement behavior clear.
- Conversion should act on the pane the user right-clicked, even if focus state is stale or another pane was previously active.
- The browser pane should feel like part of the existing split layout, not like a modal or external window.
- Browser chrome should remain compact so the pane can be useful beside a terminal.
- Existing terminal keyboard input and focus expectations should remain predictable after conversion.
- If conversion removes a running terminal session, the UX should avoid accidental data loss; implementation should either require a safe confirmation when needed or only expose conversion when replacing the pane is considered safe.

## Open Questions

- Should conversion prompt for confirmation when the terminal pane has an active process, scrollback, or unsaved interaction context?
- Should there be a reverse action to convert a browser pane back to a terminal pane in the same MVP, or is that a follow-up feature?
- Should a converted browser pane start blank, load a configurable default URL, or reuse the browser tab default from PRD-0001?
- Should mixed browser panes participate in split focus indicators and keyboard navigation exactly like terminal panes?
- Does mixed split support require a new ADR that supersedes or updates ADR-0001 before implementation?

## Revision History

- 2026-04-26: Marked Completed after browser pane conversion delivery across commits `1dbb8d8`, `973bc81`, and `4562e0a`; verification passed with `make test`, `make build-app`, and `make lint`.
- 2026-04-26: Marked Active before implementation begins; linked ADR-0002 for mixed split architecture.
- 2026-04-26: Draft created for right-click terminal pane to browser pane conversion scope.
