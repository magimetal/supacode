# ADR-0002: Browser Panes in Mixed Split Layouts

- **Status:** Accepted
- **Date:** 2026-04-26
- **Decision Maker:** Magi Metal
- **Related:** [ADR-0001: Embedded Browser Tabs with WebKit Surface Model](0001-embedded-browser-tabs-with-webkit-surface-model.md)
- **Supersedes:** ADR-0001

## Context

ADR-0001 introduced embedded browser support as top-level browser tabs only. That decision explicitly deferred mixed terminal/browser split leaves because the existing runtime was terminal-centered: `WorktreeTerminalState` owned `SplitTree<GhosttySurfaceView>` instances keyed by `TerminalTabID`, terminal surfaces were tracked in a `surfaces: [UUID: GhosttySurfaceView]` map, and browser state lived separately as `browserSurfaces: [TerminalTabID: BrowserSurfaceState]`.

The current feature request changes the target interaction: a user should be able to convert an active tab, pane, or split into a browser window/pane so browser content can sit side-by-side with terminal content. That materially reverses ADR-0001's "browser tabs first, mixed split surfaces later" boundary. The architecture now needs heterogeneous split leaves while preserving existing top-level tab mechanics and avoiding cmux-scale browser scope.

## Decision Drivers

- Support side-by-side terminal and browser content inside one worktree tab.
- Preserve existing tab mechanics (`TerminalTabManager`, selected tab behavior, close/select semantics) while changing split leaves to support multiple content kinds.
- Avoid creating a terminal `GhosttySurfaceView` when the intended replacement leaf is a browser.
- Keep `BrowserSurfaceState` as the WebKit owner for browser lifecycle, navigation state, title updates, and shared `WKProcessPool` behavior.
- Minimize churn by introducing a split content abstraction at the leaf boundary instead of broadly renaming every `Terminal*` type first.
- Keep the MVP constrained: no browser layout persistence, profiles, history suggestions, devtools UI, proxy controls, or cmux extras unless a later decision records them.

## Options Considered

### Option A: Keep browser support as top-level tabs only

- Pros: Lowest implementation risk; matches ADR-0001; avoids touching split-tree rendering, focus, drag/drop, and close semantics.
- Cons: Does not satisfy the requested side-by-side workflow.
- Cons: Keeps browser state separate from pane operations, so converting an active pane to a browser is not a natural model operation.
- Cons: Forces users to switch tabs instead of composing terminal and browser context in one layout.

### Option B: Introduce heterogeneous split leaf content for terminal and browser panes

- Pros: Directly supports replacing an active terminal pane with a browser pane in the same split layout.
- Pros: Keeps the stable top-level tab model while moving heterogeneity to the split leaf boundary where the UX requires it.
- Pros: Creates a foundation for future split operations over non-terminal content without requiring immediate global type renames.
- Cons: Requires changes to split tree storage, rendering, focus tracking, pane close behavior, and command eligibility checks.
- Cons: Adds short-term complexity because terminal-specific code must guard or branch on leaf content kind.
- Cons: Browser persistence and full browser command parity remain intentionally deferred.

### Option C: Add a separate browser side panel or secondary window outside split trees

- Pros: Avoids changing `SplitTree<GhosttySurfaceView>` and terminal pane operations.
- Pros: Can provide side-by-side visual layout with less split-tree risk.
- Cons: Creates a parallel layout system that does not behave like existing panes.
- Cons: Does not satisfy converting an active pane/split into browser content.
- Cons: Increases long-term UI and focus complexity by duplicating split behavior outside the split model.

## Decision

Chosen: **Option B: Introduce heterogeneous split leaf content for terminal and browser panes**.

Rationale: The requested workflow is pane-level composition, not only tab-level navigation. Supacode should allow an active terminal leaf to be replaced by a browser leaf inside the existing split layout, backed by a split content abstraction that can represent terminal and browser leaves. Top-level tab behavior remains in place, but the split tree must no longer be typed only as `SplitTree<GhosttySurfaceView>` for tabs that can contain browser panes.

Browser panes should reuse `BrowserSurfaceState` for WebKit ownership and navigation state. Terminal leaves should continue to use `GhosttySurfaceView`. The MVP should support creating/replacing a leaf with a browser pane and rendering it side-by-side with terminal panes; it should not attempt browser layout persistence or broader cmux browser features.

## Consequences

- **Positive:** Users can place browser and terminal content side-by-side in one worktree tab.
- **Positive:** The app gains a real split content boundary for terminal/browser surfaces instead of special-casing browser only at the tab layer.
- **Positive:** Existing tab manager semantics can remain mostly stable while pane rendering and operations become content-aware.
- **Positive:** Future surface kinds can be introduced at the split leaf boundary if needed.
- **Negative:** Split-tree storage and UI code must stop assuming every leaf is a `GhosttySurfaceView`.
- **Negative:** Focus, close, drag/drop, zoom, and command routing need content-kind checks to avoid sending terminal-only commands to browser panes.
- **Negative:** Existing terminal layout snapshots cannot fully represent browser panes in the MVP unless a later implementation explicitly extends persistence.
- **Follow-on constraints:** Do not create a placeholder terminal surface when replacing a pane with a browser; browser leaves must be represented as browser content, not hidden terminal leaves.
- **Follow-on constraints:** Preserve terminal behavior for terminal leaves, including Ghostty split actions and inherited terminal configuration.
- **Follow-on constraints:** Browser pane MVP excludes browser persistence, profiles, devtools UI, proxy support, history suggestions, storage inspection, and broad `Terminal*` renames.

## Implementation Impact

- **supacode app:** Introduce a split leaf content model such as a terminal/browser enum or wrapper that can be stored in split trees and rendered by the terminal worktree UI.
- **Terminal/worktree runtime:** Replace or adapt `SplitTree<GhosttySurfaceView>` usage in `WorktreeTerminalState` so a tab can contain both terminal leaves and browser leaves. Keep terminal-specific surface maps for `GhosttySurfaceView` and add browser-pane tracking keyed by pane/surface identifiers, not only by top-level tab ID.
- **Browser runtime:** Continue using `BrowserSurfaceState` as the `WKWebView` owner. Allow browser surfaces to exist as pane leaves as well as, if still supported, browser-only top-level tabs.
- **Command routing:** Add a focused/menu/context-menu action that replaces the active pane with a browser pane. Terminal-only commands must be disabled or ignored for browser panes; browser commands must target the focused browser pane.
- **Persistence:** Do not persist browser panes in the MVP unless explicitly designed later. Existing terminal-only layout restore should remain compatible and must not synthesize unwanted browser or terminal panes.
- **Migration/ops:** No external dependency or deployment pipeline change is expected; WebKit remains the platform browser framework.

## Verification

- **Automated:** Add tests for replacing an active terminal pane with a browser pane, preserving neighboring terminal panes, not creating an unwanted `GhosttySurfaceView`, closing browser panes, and keeping terminal-only commands scoped to terminal leaves.
- **Automated:** Add compatibility coverage for existing terminal layout snapshot restore behavior so terminal-only layouts still restore correctly.
- **Manual:** In the running app, create a split terminal layout, invoke the context-menu or focused action to convert one pane to a browser pane, load a URL, verify the browser and terminal remain side-by-side, switch focus between panes, close the browser pane, and verify terminal splits still work.
- **Documentation:** Read back this ADR, ADR-0001, and `docs/adr/README.md` to confirm the supersession chain and index are consistent.

## Notes

- This ADR supersedes ADR-0001 because it materially changes the deferred mixed split decision.
- Keep the implementation lean: solve pane-level browser conversion first, then revisit persistence or broader surface renames after behavior is proven stable.
- Current code evidence includes `TerminalTabKind.browser`, `BrowserSurfaceState`, top-level `browserSurfaces: [TerminalTabID: BrowserSurfaceState]`, and terminal-only `SplitTree<GhosttySurfaceView>` storage.

## Status History

- 2026-04-26: Accepted
