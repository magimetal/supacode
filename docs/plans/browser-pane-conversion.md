# Browser Pane Conversion — Heterogeneous Split Leaves Plan

## Objective

Implement the MVP for converting a right-clicked terminal pane inside an existing split layout into an embedded browser pane, so terminal and browser content can sit side-by-side in one Supacode worktree tab.

This plan is constrained to the PRD/ADR-approved conversion path. It does **not** add browser pane persistence/restore, arbitrary browser-pane split creation, reverse conversion, cmux browser extras, or broad `Terminal*` renames.

## Source Documents

- PRD: `docs/prd/0002-browser-pane-conversion.md`
- ADR: `docs/adr/0002-browser-panes-in-mixed-split-layouts.md`
- Superseded ADR context: `docs/adr/0001-embedded-browser-tabs-with-webkit-surface-model.md`

Note: caller context named `docs/adr/0002-heterogeneous-browser-terminal-split-panes.md`; observed repo file is `docs/adr/0002-browser-panes-in-mixed-split-layouts.md`.

## Current Repo Evidence Used

- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
  - Currently stores split trees as `private var trees: [TerminalTabID: SplitTree<GhosttySurfaceView>]`.
  - Tracks terminal surfaces in `private var surfaces: [UUID: GhosttySurfaceView]`.
  - Tracks top-level browser tabs in `private var browserSurfaces: [TerminalTabID: BrowserSurfaceState]`.
  - `splitTree(for:)` creates a terminal `GhosttySurfaceView` when a tree is missing.
  - Split, focus, close, notification, busy-state, and snapshot code currently assumes leaves are terminal surfaces.
- `supacode/Features/Terminal/Models/SplitTree.swift`
  - Generic over `NSView & Identifiable`; reusable if leaves become an `NSView` wrapper rather than direct `GhosttySurfaceView`.
  - Provides `replacing(node:with:)`, `removing(_:)`, focus navigation, drag/drop insertion, zoom, resizing, and structural identity.
- `supacode/Features/Terminal/Views/TerminalSplitTreeView.swift`
  - Renders `SplitTree<GhosttySurfaceView>` leaves with `GhosttyTerminalView` and terminal-specific overlays.
  - Has the pane-level right-click insertion point via SwiftUI `.contextMenu` on `LeafView`; no pane context menu exists today.
  - Drag/drop, accessibility, notification dots, search overlay, progress overlay, and dim overlay are terminal-leaf-specific.
- `supacode/Features/Terminal/Views/WorktreeTerminalTabsView.swift`
  - Top-level tab content switches on `TerminalTabKind` and renders `BrowserTabView` for `.browser` tabs or `TerminalSplitTreeAXContainer` for `.terminal` tabs.
  - Split toolbar buttons are gated only by selected tab kind, not active leaf kind.
- `supacode/Features/Browser/Models/BrowserSurfaceState.swift`
  - Existing `@MainActor @Observable` WebKit owner with `id`, `webView`, navigation state, `load`, `navigateSmart`, `goBack`, `goForward`, and `reloadOrStop`.
- `supacode/Features/Browser/Views/BrowserTabView.swift`
  - Existing reusable browser chrome + `BrowserWebViewRepresentable` view.
- `supacode/Clients/Terminal/TerminalClient.swift`
  - Existing command bridge has `createBrowserTab`, terminal split/destroy/focus commands, but no pane conversion command.
- `supacode/Features/Terminal/BusinessLogic/WorktreeTerminalManager.swift`
  - Routes `TerminalClient.Command` to `WorktreeTerminalState`.
- Tests exist in:
  - `supacodeTests/WorktreeTerminalManagerTests.swift`
  - `supacodeTests/SplitTreeTests.swift`
  - `supacodeTests/TerminalLayoutSnapshotTests.swift`
  - `supacodeTests/AppFeatureBrowserTabTests.swift`

## Implementation-Ready Scope

### In scope

- Add a heterogeneous split leaf model that can represent a terminal leaf or browser leaf.
- Replace the right-clicked terminal leaf with a browser leaf in the same split-tree position.
- Reuse `BrowserSurfaceState` and `BrowserTabView`/browser chrome for browser pane rendering where practical.
- Wire a terminal pane context menu action named **Convert Pane to Browser**.
- Route conversion by the right-clicked pane ID, not by stale focused pane state.
- Clean up the replaced terminal `GhosttySurfaceView` and related per-surface state.
- Keep neighboring terminal panes usable after conversion.
- Keep terminal-only tabs and top-level browser tabs working.
- Add focused automated tests for model conversion, cleanup, command routing, terminal-only regressions, and snapshot compatibility.

### Explicitly out of scope

- Browser pane persistence or restore across app launches.
- Creating browser panes by split toolbar button, drag/drop, keyboard shortcut, CLI command, or command palette outside the conversion flow.
- Reverse action to convert a browser pane back to terminal.
- Mixed browser split creation except replacing a terminal pane.
- Browser profiles, history suggestions, importers, proxy controls, storage inspector, custom DevTools UI, find-in-page, or broad browser command suite.
- Broad `Terminal*` type/directory renames.
- Killing the actively running dev app unless a later execution task explicitly requires it.

## Proposed Design

### Leaf identity and content

Introduce a split leaf wrapper that is stable by pane ID and can hold either terminal or browser content:

```swift
@MainActor
final class WorktreePaneSurface: NSView, Identifiable {
  let id: UUID
  var content: WorktreePaneContent
}

enum WorktreePaneContent {
  case terminal(GhosttySurfaceView)
  case browser(BrowserSurfaceState)
}
```

Names may be adjusted during implementation, but keep the boundary explicit: split leaves are panes; pane content is terminal or browser.

Rationale: `SplitTree` already requires `NSView & Identifiable` and compares leaves by object identity. A wrapper avoids forcing `BrowserSurfaceState` to become an `NSView`, preserves split-tree mechanics, and gives a stable ID for focus, right-click targeting, drag/drop, and close. Terminal-specific code can unwrap `.terminal` only where needed.

### Runtime ownership

In `WorktreeTerminalState`:

- Replace `trees: [TerminalTabID: SplitTree<GhosttySurfaceView>]` with `paneTrees: [TerminalTabID: SplitTree<WorktreePaneSurface>]` or similarly named storage.
- Keep `surfaces: [UUID: GhosttySurfaceView]` as terminal-only lookup for existing terminal integrations.
- Add `browserPaneSurfaces: [UUID: BrowserSurfaceState]` keyed by pane ID.
- Keep top-level `browserSurfaces: [TerminalTabID: BrowserSurfaceState]` for existing `.browser` tabs unless implementation decides to unify it safely without broad scope expansion.
- Preserve terminal tab kind semantics: mixed split tabs remain top-level `.terminal` tabs containing mixed leaves.

### Conversion operation

Add a single state-level method:

```swift
@discardableResult
func convertTerminalPaneToBrowser(surfaceID: UUID, initialURL: URL? = nil) -> Bool
```

Expected flow:

1. Resolve the tab containing `surfaceID`.
2. Ensure the target leaf exists and its content is `.terminal`.
3. Create a `BrowserSurfaceState(id: surfaceID)` or create a browser state with a new ID and pane wrapper using the old pane ID; prefer preserving the pane ID if compatible with existing callers.
4. Set browser title callback to update the tab title only when this browser pane is the active pane in the selected/mixed tab.
5. Replace the target leaf node in the tree with a browser leaf using `SplitTree.replacing(node:with:)`.
6. Remove the terminal surface from `surfaces`, close the underlying Ghostty surface, and clean per-surface state such as notifications/recent hooks for that terminal surface.
7. Store browser state in `browserPaneSurfaces`.
8. Mark the browser pane active for that tab, clear or update terminal focus as needed, and avoid sending terminal focus commands to the browser leaf.
9. Log with `SupaLogger("Terminal")` or a focused browser-pane logger; do not use `print`.

No confirmation dialog is required for the MVP unless an existing close/protection hook makes it trivial and low-risk. The PRD calls the data-loss behavior an open question; do not add a modal flow in the first pass unless product explicitly answers it.

### Rendering

Refactor `TerminalSplitTreeView` into mixed leaf rendering without broad renaming if possible:

- Accept `SplitTree<WorktreePaneSurface>`.
- Render `.terminal` leaves with existing `GhosttyTerminalView` and terminal-only overlays.
- Render `.browser` leaves with `BrowserTabView(surface:)` or a small `BrowserPaneView` wrapper that reuses the same chrome and `BrowserWebViewRepresentable`.
- Keep dim overlay and split geometry behavior content-agnostic.
- Keep terminal progress/search overlays terminal-only.
- Show notification dot only for terminal leaves in the MVP, unless notification state is explicitly generalized.
- Disable terminal drag/drop for browser leaves unless implementation can safely make it pane-generic without expanding scope. The safe MVP is: existing terminal-pane drag/drop remains for terminal leaves; browser leaves are not draggable targets/sources beyond resizing/equalizing.
- Update accessibility labels to describe mixed panes, e.g. `Worktree split: N panes`; terminal panes remain accessibility children where AppKit requires direct `GhosttySurfaceView` children. Browser accessibility can rely on WebKit defaults for MVP.

### Context menu and command routing

- Add `.contextMenu` to `TerminalSplitTreeView.LeafView` for terminal leaves only.
- Menu label: `Convert Pane to Browser`.
- The action must capture the leaf's own pane/surface ID and call state conversion for that ID.
- Do not rely on `activeSurfaceID` to choose the target.
- If adding an app-level command is useful for testability, add a narrowly scoped `TerminalClient.Command.convertSurfaceToBrowser(Worktree, tabID: TerminalTabID, surfaceID: UUID, initialURL: URL? = nil)` and route it in `WorktreeTerminalManager`. Do not expose CLI or command-palette UI in the MVP.
- Avoid top-level `createBrowserTab` paths during conversion.

## Tasks

### Task 1 — Introduce the heterogeneous pane leaf model

**What**

Add a minimal leaf wrapper/content model that lets the existing split tree hold terminal and browser leaves.

**References**

- `supacode/Features/Terminal/Models/SplitTree.swift`
- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
- New candidate file: `supacode/Features/Terminal/Models/WorktreePaneSurface.swift`
- `docs/adr/0002-browser-panes-in-mixed-split-layouts.md`

**Acceptance criteria**

- A split tree can store terminal and browser leaf wrappers without changing `SplitTree`'s public behavior.
- Terminal leaf IDs remain the IDs used by existing terminal surface commands.
- Browser leaf IDs are stable and unique.
- No browser leaf creates or hides a placeholder `GhosttySurfaceView`.

**Guardrails**

- Do not rewrite `SplitTree` unless the wrapper approach proves impossible.
- Do not broadly rename terminal feature directories/types.
- Do not make browser state conform to `NSView`; keep WebKit ownership in `BrowserSurfaceState`.

**Verification**

- Add/adjust unit tests in `supacodeTests/SplitTreeTests.swift` or a new focused pane-surface test proving replacement preserves sibling structure and IDs.
- Later full-pass command: `make test`.

### Task 2 — Migrate `WorktreeTerminalState` storage to mixed pane trees

**What**

Change runtime storage and helper methods from terminal-only split leaves to mixed pane leaves while preserving terminal-only behavior.

**References**

- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
- `supacode/Features/Terminal/BusinessLogic/WorktreeTerminalManager.swift`
- `supacode/Features/Terminal/Models/TerminalTabItem.swift`
- `supacode/Features/Browser/Models/BrowserSurfaceState.swift`

**Acceptance criteria**

- Existing terminal tab creation still creates a terminal pane and selects/focuses it.
- Existing top-level browser tab creation still creates a `.browser` tab and does not create a terminal tree.
- Existing terminal-only split creation, navigation, resizing, zooming, close, and drag/drop behavior works for terminal leaves.
- Mixed tabs remain `TerminalTabKind.terminal`; conversion does not create a new top-level browser tab.
- Terminal-only lookup methods such as `hasSurface`, `hasSurfaceAnywhere`, `listSurfaces`, and `tabID(containing:)` continue to report terminal surfaces correctly.

**Guardrails**

- Keep `surfaces: [UUID: GhosttySurfaceView]` terminal-only.
- Add browser-pane storage keyed by pane ID; do not overload top-level `browserSurfaces: [TerminalTabID: BrowserSurfaceState]` in a way that breaks current browser tabs.
- Do not send terminal binding actions to browser leaves.
- Do not change CLI-visible terminal surface semantics except to ensure converted terminal panes no longer appear as terminal surfaces.

**Verification**

- Add tests to `supacodeTests/WorktreeTerminalManagerTests.swift` or a new state test file:
  - terminal tabs still have terminal trees;
  - top-level browser tabs still do not have terminal trees;
  - terminal split commands still add terminal leaves;
  - terminal commands no-op or fail safely when targeted at a converted browser pane.
- Later full-pass command: `make test`.

### Task 3 — Implement conversion as a state operation

**What**

Add the core method that replaces one terminal leaf with one browser leaf in the same split position.

**References**

- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
- `supacode/Features/Terminal/Models/SplitTree.swift`
- `supacode/Features/Browser/Models/BrowserSurfaceState.swift`
- `supacode/Features/Terminal/Models/WorktreeTerminalNotification.swift`

**Acceptance criteria**

- Calling conversion with a valid terminal surface ID returns `true`.
- The split tree has the same structure and leaf count after conversion.
- The target leaf renders/identifies as browser content after conversion.
- Sibling terminal leaves remain in `surfaces` and continue to focus/accept split actions.
- The replaced terminal surface is closed and removed from `surfaces`.
- Per-terminal state for the replaced surface is cleaned up where applicable: recent hook cache, unread notifications tied to that surface, focused terminal mapping if needed, busy/dirty recalculation.
- Calling conversion with an unknown surface ID or non-terminal/browser pane ID returns `false` and logs a warning/debug message.

**Guardrails**

- Do not call `createBrowserTab` for pane conversion.
- Do not call `splitTree(for:)` in a way that synthesizes a new terminal surface for browser content.
- Do not add browser persistence here.
- Do not silently discard errors from `SplitTree.replacing`; log and leave the original terminal pane intact on failure.

**Verification**

- Add tests proving:
  - conversion succeeds for an existing terminal leaf;
  - conversion preserves sibling terminal panes;
  - conversion does not create an additional `GhosttySurfaceView`;
  - invalid conversion target is safe;
  - close-all cleanup removes browser pane state.
- Later full-pass command: `make test`.

### Task 4 — Make focus, close, and terminal commands content-aware

**What**

Update pane focus/close/action paths so terminal-only operations only act on terminal leaves and browser leaves remain stable.

**References**

- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
- `supacode/Features/Terminal/Views/WorktreeTerminalTabsView.swift`
- `supacode/Features/Terminal/Views/TerminalSplitTreeView.swift`
- `supacode/Clients/Terminal/TerminalClient.swift`

**Acceptance criteria**

- Focusing a terminal leaf still calls Ghostty focus paths.
- Selecting/focusing a browser pane records it as the active pane without calling Ghostty focus APIs on browser content.
- `closeFocusedSurface` closes/removes either a terminal pane or browser pane safely.
- Closing a browser pane collapses the split tree like terminal pane removal and focuses a neighboring terminal pane if one exists.
- Terminal binding/search commands no-op safely when the active pane is browser content.
- Tab dirty/running state reflects only terminal leaves.
- Split toolbar buttons are enabled only when the active leaf is terminal, not merely when the top-level tab kind is `.terminal`.

**Guardrails**

- Do not implement browser-specific keyboard command routing beyond basic WebKit field/web view behavior.
- Do not add reverse conversion or browser split creation.
- Preserve current terminal focus event emissions for terminal leaves.

**Verification**

- Add tests for active pane tracking across terminal and browser leaves.
- Add tests for close focused browser pane and terminal command no-op behavior.
- Manually verify after implementation: click terminal pane, type; click browser address field, type URL; return to terminal, type.

### Task 5 — Render mixed split panes

**What**

Update split rendering to branch by leaf content and reuse browser UI for browser pane leaves.

**References**

- `supacode/Features/Terminal/Views/TerminalSplitTreeView.swift`
- `supacode/Features/Terminal/Views/WorktreeTerminalTabsView.swift`
- `supacode/Features/Browser/Views/BrowserTabView.swift`
- `supacode/Features/Browser/Views/BrowserWebViewRepresentable.swift`
- `supacode/Features/Terminal/Views/GhosttySurfaceProgressOverlay.swift`
- `supacode/Features/Terminal/Views/GhosttySurfaceSearchOverlay.swift`

**Acceptance criteria**

- A mixed split can display at least one terminal pane and one browser pane side-by-side in one top-level tab.
- Terminal leaves keep current overlays: progress, search, notification dot, drag handle where valid, dim overlay.
- Browser leaves render browser chrome and WebKit content using existing browser surface state.
- Conversion does not show `Browser unavailable` unless browser state is actually missing.
- Existing top-level browser tab rendering remains unchanged.

**Guardrails**

- Do not duplicate browser chrome logic extensively; extract a shared internal browser content view only if needed.
- Do not make terminal notification/search overlays appear on browser leaves.
- Do not add new buttons without `.help(...)` tooltips; context menu entries do not need tooltips.

**Verification**

- Add lightweight rendering/model tests where practical; rely on manual browser validation for WebKit display.
- Manual check after implementation in the running dev app: split terminal, right-click one pane, convert, load `https://example.com`, verify side-by-side behavior.

### Task 6 — Wire pane context menu and optional command bridge

**What**

Expose the MVP action from the right-click menu on terminal pane leaves and route it to the exact right-clicked surface.

**References**

- `supacode/Features/Terminal/Views/TerminalSplitTreeView.swift`
- `supacode/Features/Terminal/Views/WorktreeTerminalTabsView.swift`
- Optional: `supacode/Clients/Terminal/TerminalClient.swift`
- Optional: `supacode/Features/Terminal/BusinessLogic/WorktreeTerminalManager.swift`

**Acceptance criteria**

- Right-clicking a terminal pane shows `Convert Pane to Browser`.
- Invoking the menu item converts the pane that was right-clicked, even if another pane was active before the right-click.
- The menu item is not shown for browser leaves.
- Conversion does not create a top-level browser tab.
- Context menu wiring is local to pane leaves; top-level tab context menu remains about tabs only.

**Guardrails**

- Do not add a global keyboard shortcut in this MVP.
- Do not add command-palette or CLI exposure unless required by tests; if added, keep it hidden/narrow and use explicit tab/surface IDs.
- Do not reuse `TerminalTabContextMenu`, which is tab-level, for pane-level behavior.

**Verification**

- Add a test for command bridge routing if a `TerminalClient.Command` is introduced.
- Manual check after implementation: right-click first of two split terminals while second is focused; verify first pane is replaced.

### Task 7 — Preserve snapshot compatibility without browser pane persistence

**What**

Keep layout snapshot capture/restore safe for terminal-only layouts and avoid persisting browser panes in the MVP.

**References**

- `supacode/Features/Terminal/Models/TerminalLayoutSnapshot.swift`
- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
- `supacodeTests/TerminalLayoutSnapshotTests.swift`

**Acceptance criteria**

- Existing terminal-only snapshots still encode/decode and restore as before.
- Capturing a layout containing browser panes does not corrupt saved terminal restore data.
- MVP behavior is explicit in code comments/tests: browser panes are runtime-only.
- If mixed tabs are skipped during snapshot capture, the behavior is logged and does not crash.
- If only terminal leaves are captured from a mixed tree, the resulting layout must be structurally valid; otherwise prefer skipping the mixed tab for MVP safety.

**Guardrails**

- Do not extend `TerminalLayoutSnapshot` with browser pane schema in this pass.
- Do not synthesize terminal placeholders for browser panes during capture or restore.
- Do not silently save malformed split trees.

**Verification**

- Add tests covering terminal-only snapshot compatibility.
- Add a test for capture behavior with a mixed tab: expected result should be either skipped mixed tab or safe terminal-only snapshot, whichever implementation chooses and documents.
- Later full-pass command: `make test`.

### Task 8 — Lifecycle cleanup and pruning

**What**

Ensure browser pane state and terminal state are cleaned up correctly when panes, tabs, worktrees, or all surfaces close.

**References**

- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
- `supacode/Features/Terminal/BusinessLogic/WorktreeTerminalManager.swift`
- `supacode/Features/Browser/Models/BrowserSurfaceState.swift`

**Acceptance criteria**

- Converting a terminal pane closes/removes only that terminal surface.
- Closing a browser pane removes its `BrowserSurfaceState` from browser-pane storage.
- Closing a mixed tab cleans up all terminal and browser leaves in that tab.
- `closeAllSurfaces()` clears terminal surfaces, split trees, top-level browser surfaces, browser-pane surfaces, focus maps, busy maps, and blocking-script state as appropriate.
- `prune(keeping:)` still saves snapshots safely and then cleans all mixed content for removed worktrees.

**Guardrails**

- Do not call terminal `closeSurface()` on browser leaves.
- Do not leak browser pane states after tree removal.
- Do not mark browser panes as terminal busy/dirty.

**Verification**

- Add state tests for close browser pane, close mixed tab, and close all surfaces.
- Later full-pass command: `make test`.

### Task 9 — Verification pass and manual MVP checklist

**What**

Run focused automated verification and manually validate the browser-facing flow in the running app after implementation.

**References**

- `Makefile`
- `supacodeTests/WorktreeTerminalManagerTests.swift`
- `supacodeTests/SplitTreeTests.swift`
- `supacodeTests/TerminalLayoutSnapshotTests.swift`
- `supacodeTests/AppFeatureBrowserTabTests.swift`
- Running dev app via existing `dev make` session, if still active.

**Acceptance criteria**

- Automated tests pass.
- Manual conversion path works in a real app window.
- No unintended top-level browser tab appears during pane conversion.
- Terminal-only tabs, splits, focus, input, search, notifications, and setup-script flows have no obvious regression.

**Guardrails**

- Do not kill the running dev app unless explicitly authorized or necessary to unblock verification.
- Do not claim browser/UI verification without observing the running app or a browser-visible UI state.
- Keep any follow-up issues separate from MVP completion.

**Verification commands for implementation phase**

- `make test`
- `make build-app`
- `make lint`
- If project convention prefers the combined check: `make check`

**Manual checklist for implementation phase**

1. Launch/open a worktree with a terminal tab.
2. Create a side-by-side terminal split.
3. Focus the right terminal pane.
4. Right-click the left terminal pane and choose `Convert Pane to Browser`.
5. Confirm the left pane becomes a browser and the right terminal pane remains usable.
6. Load `https://example.com` in the browser pane.
7. Use browser back/forward/reload controls enough to confirm chrome is wired.
8. Click back into the terminal pane and type a harmless command such as `pwd`.
9. Close the browser pane; confirm split collapses and no crash occurs.
10. Create a new terminal tab and split it to confirm terminal-only behavior still works.

## Risky Files / Areas

- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
  - Highest risk: core runtime owns split trees, focus, close, notifications, layout snapshots, busy state, terminal creation, and top-level browser tab state.
- `supacode/Features/Terminal/Views/TerminalSplitTreeView.swift`
  - High risk: rendering, drag/drop, overlays, accessibility container, and pane context menu all currently assume `GhosttySurfaceView` leaves.
- `supacode/Features/Terminal/Views/WorktreeTerminalTabsView.swift`
  - Medium risk: tab rendering and split toolbar gating must become active-leaf-aware.
- `supacode/Features/Terminal/Models/TerminalLayoutSnapshot.swift`
  - Medium risk: persistence must remain compatible while browser panes stay runtime-only.
- `supacode/Clients/Terminal/TerminalClient.swift` and `supacode/Features/Terminal/BusinessLogic/WorktreeTerminalManager.swift`
  - Medium risk only if a command bridge is introduced; route by explicit tab/surface IDs.
- `supacode/Features/Browser/Views/BrowserTabView.swift`
  - Lower risk: likely reusable, but may need extraction if top-level tab and pane chrome diverge.

## Key Assumptions

- `SplitTree` can remain structurally unchanged by wrapping leaves in an `NSView & Identifiable` pane object.
- Mixed split tabs can stay classified as `.terminal` at the top-level tab kind for MVP.
- Browser panes are runtime-only and may be skipped during layout snapshot capture.
- The MVP can convert a terminal pane without adding a confirmation dialog for active terminal processes; this remains a product risk from the PRD open questions.
- Existing `BrowserSurfaceState` is sufficient for browser panes without additional WebKit lifecycle changes.

## Open Risks / Unknowns

- Active-process data loss: converting a terminal pane closes that terminal surface. Product has not decided whether confirmation is required.
- Accessibility for mixed panes may need follow-up if WebKit children do not integrate cleanly with the existing terminal split AX container.
- Drag/drop behavior for browser leaves is intentionally limited in MVP; users may expect all panes to be draggable later.
- Snapshot behavior for mixed layouts must be conservative to avoid losing terminal restore integrity.
- Focus between `WKWebView`, browser address `TextField`, and Ghostty terminal surfaces may expose AppKit responder edge cases requiring follow-up.
