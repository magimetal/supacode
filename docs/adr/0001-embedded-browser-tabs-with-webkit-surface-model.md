# ADR-0001: Embedded Browser Tabs with WebKit Surface Model

- **Status:** Accepted
- **Date:** 2026-04-26
- **Decision Maker:** Magi Metal
- **Related:** [Embedded Browser Tabs Feasibility and Implementation Plan](../plans/embedded-browser-tabs.md)
- **Supersedes:** None

## Context

Supacode is a macOS Swift/TCA app whose worktree surface is currently terminal-centered. Existing tab, split, focus, command, and layout primitives live around `WorktreeTerminalManager`, `WorktreeTerminalState`, `TerminalTabManager`, `TerminalTabItem`, and `SplitTree<GhosttySurfaceView>`.

The embedded browser tabs plan proposes adding web browser tabs inspired by cmux. The key architectural constraint is that current tabs and split leaves assume terminal content. Browser support therefore needs a content model that can introduce `WKWebView` without forcing an immediate broad rename or mixed terminal/browser split abstraction.

This ADR records the architecture decision before implementation so the MVP remains constrained: browser tabs first, mixed split surfaces later.

## Decision Drivers

- Add embedded web browsing as a new worktree surface without destabilizing existing terminal behavior.
- Use platform-native WebKit (`WKWebView`) rather than adding a third-party browser/runtime dependency.
- Preserve existing `WorktreeTerminalManager` / `WorktreeTerminalState` ownership for the MVP to minimize churn.
- Add explicit tab kind metadata so UI, persistence, and command routing can distinguish terminal and browser tabs.
- Keep terminal-only split infrastructure intact until browser top-level tabs, persistence, and keyboard behavior prove stable.
- Avoid broad `Terminal*` type renames during the MVP.
- Use Supacode conventions: `@MainActor @Observable` runtime models, TCA for app-level command dispatch, and `SupaLogger` for logging.

## Options Considered

### Option A: Top-level browser tabs backed by WebKit, owned by existing worktree terminal state

- Pros: Smallest viable architectural change; reuses existing tab bar, selected-tab behavior, close/select mechanics, focused worktree command path, and persistence entry points.
- Pros: Avoids changing `SplitTree<GhosttySurfaceView>` before browser behavior and keyboard/focus risks are understood.
- Pros: Allows browser-specific state (`BrowserSurfaceState`) to own `WKWebView` lifecycle cleanly.
- Cons: Keeps naming debt because browser tabs initially live under `WorktreeTerminalState` and related `Terminal*` types.
- Cons: Does not deliver mixed terminal/browser splits in the first implementation phase.

### Option B: Introduce a full generic worktree surface abstraction before browser MVP

- Pros: Cleaner long-term model for terminal, browser, and future surface kinds.
- Pros: Mixed terminal/browser split support could be designed from the start.
- Cons: Larger refactor across split trees, focus management, accessibility containers, command routing, layout snapshots, and tests.
- Cons: Higher risk of terminal regressions before validating that embedded browser tabs are useful and stable.
- Cons: Violates the MVP constraint to avoid broad `Terminal*` renames and abstraction churn.

### Option C: Use an external browser or open URLs outside Supacode

- Pros: Minimal implementation complexity and avoids `WKWebView` focus/session concerns.
- Cons: Does not satisfy embedded browser tabs UX.
- Cons: Cannot share Supacode tab/focus/layout affordances.
- Cons: Fails to create a foundation for future mixed worktree surfaces.

## Decision

Chosen: **Option A: Top-level browser tabs backed by WebKit, owned by existing worktree terminal state**.

Rationale: Browser tabs should be introduced as a new tab content kind using WebKit/WKWebView and a dedicated browser surface model. The implementation will add `TerminalTabKind` metadata, create browser tabs as top-level tabs first, and store browser state in `WorktreeTerminalState` keyed by tab ID. `WorktreeTerminalManager` and `WorktreeTerminalState` remain the owning runtime layer for the MVP. Mixed terminal/browser split abstraction is explicitly deferred until top-level browser tabs, persistence, and focus/keyboard behavior are stable.

## Consequences

- **Positive:** Browser tab implementation can start without a large split-tree refactor.
- **Positive:** Existing terminal tab creation and rendering can remain the default path by assigning legacy/unspecified tabs `.terminal` kind.
- **Positive:** The app gets an explicit model boundary for browser state, URL resolution, WebKit lifecycle, and browser commands.
- **Positive:** The plan keeps future mixed split support possible by adding content kind metadata now.
- **Negative:** Browser support initially lives in terminal-named types, increasing short-term naming debt.
- **Negative:** Mixed terminal/browser splits are not part of the MVP and will require a later surface abstraction over `SplitTree<GhosttySurfaceView>`.
- **Negative:** `WKWebView` focus and command-equivalent behavior may require additional testing and possibly a subclass if native behavior conflicts with app shortcuts.
- **Follow-on constraints:** Do not call `state.splitTree(for:)` for browser tabs; that would create unwanted `GhosttySurfaceView` terminal state.
- **Follow-on constraints:** Do not rename terminal feature directories/types broadly until after the browser MVP proves stable.
- **Follow-on constraints:** Do not add cmux-scale browser features such as profiles, importers, devtools UI, proxy support, history suggestions, or storage inspection in the MVP.

## Implementation Impact

- **supacode app:** Add browser feature files such as `BrowserSurfaceState`, `BrowserURLResolver`, `BrowserTabView`, and a SwiftUI/AppKit wrapper for `WKWebView`.
- **Terminal/worktree runtime:** Extend `TerminalTabItem` / `TerminalTabManager` with tab kind metadata; add browser state storage and browser tab creation to `WorktreeTerminalState`; keep `WorktreeTerminalManager` ownership.
- **Command routing:** Add a focused/menu action for **New Browser Tab** that dispatches through existing app/worktree command paths without stealing terminal shortcuts.
- **Persistence:** Extend `TerminalLayoutSnapshot` compatibly so legacy terminal-only snapshots decode as `.terminal` and browser tabs can later persist URL/title state.
- **Migration/ops:** No external dependency or deployment pipeline change is expected; WebKit is a platform framework available to the macOS app target.

## Verification

- **Automated:** Add unit tests during implementation for legacy snapshot decoding, browser URL resolution, browser tab creation without terminal split side effects, and command dispatch for new browser tab creation.
- **Manual:** After UI implementation, create terminal and browser tabs, load `https://example.com`, switch tabs, use back/forward/reload, close the browser tab, and verify terminal behavior remains intact.
- **Documentation:** Read back this ADR and `docs/adr/README.md` to confirm the decision, status, and index entry are consistent.

## Notes

- Source plan: `docs/plans/embedded-browser-tabs.md`.
- MVP browser tabs should use `WKWebView` with a shared `WKProcessPool` and default `WKWebsiteDataStore` unless privacy/isolation requirements are added later.
- Browser models should use `@MainActor @Observable`, not `ObservableObject`.
- Logging should use `SupaLogger("Browser")`, not `print` or `os.Logger`.
- Revisit this ADR or write a follow-up ADR before implementing mixed terminal/browser split leaves or broad `Terminal*` renames.

## Status History

- 2026-04-26: Accepted
