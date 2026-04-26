# Embedded Browser Tabs — First Implementation Pass Plan

## Objective

Implement the first coding pass for embedded browser tabs in Supacode.

This pass is intentionally constrained to **top-level browser tabs only** in the existing worktree tab bar. It must not implement mixed terminal/browser splits, broad `Terminal*` renames, browser session persistence, or cmux-scale browser features.

## Source Documents

- PRD: `docs/prd/0001-embedded-browser-tabs.md`
- ADR: `docs/adr/0001-embedded-browser-tabs-with-webkit-surface-model.md`

## Implementation-Ready Scope

### In scope for this first pass

- Add tab content kind metadata so a tab is either `.terminal` or `.browser`.
- Add minimal browser model state backed by `WKWebView`.
- Add URL/search input resolution for browser omnibar input.
- Render a selected browser tab as browser chrome + WebKit surface.
- Create browser tabs from a focused/menu action named **New Browser Tab** when a worktree is active.
- Close browser tabs through existing tab close flows.
- Keep all existing terminal tab creation, split, search, notification, and setup-script behavior unchanged.
- Add focused automated tests for metadata, URL resolution, browser tab creation side effects, and command dispatch.

### Explicitly out of scope for this first pass

- Mixed terminal/browser split panes.
- Persisting/restoring browser tabs in `TerminalLayoutSnapshot`.
- Full browser history, suggestions, profiles, devtools UI, imports, proxy support, storage inspection, or session restore.
- Find-in-page.
- Broad renaming of `Terminal*` files/types/directories.
- CLI/browser surface commands beyond app UI creation of a browser tab.
- Adding keyboard shortcuts that collide with Ghostty shortcuts.

## Current Repo Evidence Used

- `supacode/Features/Terminal/Models/TerminalTabItem.swift`
  - `TerminalTabItem` has no content kind today.
- `supacode/Features/Terminal/Models/TerminalTabManager.swift`
  - `createTab(...)` constructs `TerminalTabItem` and selects it.
- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
  - Terminal tabs currently create `SplitTree<GhosttySurfaceView>` through `splitTree(for:...)`.
  - `closeTab(_:)`, `focusSelectedTab()`, `focusSurface(in:)`, `captureLayoutSnapshot()`, and `restoreFromSnapshot(_:,focusing:)` assume terminal-backed tabs.
- `supacode/Features/Terminal/Views/WorktreeTerminalTabsView.swift`
  - Selected tab content currently always calls `state.splitTree(for: tabId)`, which would incorrectly create a terminal surface for browser tabs.
- `supacode/Clients/Terminal/TerminalClient.swift`
  - `TerminalClient.Command` is the existing app-level command bridge for worktree tab actions.
- `supacode/Features/Terminal/BusinessLogic/WorktreeTerminalManager.swift`
  - `handleTabCommand(_:)` routes `TerminalClient.Command` to `WorktreeTerminalState`.
- `supacode/Features/App/Reducer/AppFeature.swift`
  - `.newTerminal` is the model for selected-worktree guarded tab creation and analytics.
- `supacode/Commands/TerminalCommands.swift`
  - Focused values and menu command pattern already exists.
- `supacode/Features/Repositories/Views/WorktreeDetailView.swift`
  - Focused actions are currently wired via `makeFocusedActions` / `applyFocusedActions`.
- `Makefile`
  - Established verification commands are `make test`, `make build-app`, `make lint`, and `make check`.

## Tasks

### Task 1 — Add tab content kind metadata

**What**

Add an explicit tab kind to the existing tab item model while preserving terminal as the default.

**References**

- `supacode/Features/Terminal/Models/TerminalTabItem.swift`
- `supacode/Features/Terminal/Models/TerminalTabManager.swift`
- Tests:
  - `supacodeTests/TerminalRenderingPolicyTests.swift`
  - Add or update a focused tab-manager test file if one exists; otherwise add `supacodeTests/TerminalTabManagerTests.swift`.

**Implementation details**

- Add:
  - `enum TerminalTabKind: String, Codable, Equatable, Sendable { case terminal; case browser }`
- Add `var kind: TerminalTabKind` to `TerminalTabItem`.
- Default `TerminalTabItem.init(...)` to `kind: .terminal`.
- Add `kind: TerminalTabKind = .terminal` to `TerminalTabManager.createTab(...)` and pass it into `TerminalTabItem`.
- Existing terminal call sites should compile without passing `kind`.

**Acceptance criteria**

- Existing `TerminalTabItem(...)` test literals still compile by relying on `.terminal` default.
- `TerminalTabManager.createTab(...)` creates `.terminal` tabs by default.
- A new test proves `TerminalTabManager.createTab(..., kind: .browser)` stores `.browser`.

**Guardrails**

- Do not modify `TerminalLayoutSnapshot` for browser persistence in this pass.
- Do not rename `TerminalTabItem`, `TerminalTabManager`, or feature directories.
- Do not change tab ordering, selection, close, or dirty/title semantics except where browser-specific code explicitly needs it later.

**Verification**

- `make test` after the full implementation pass.
- Targeted manual readback before build: confirm all existing `createTab(...)` calls either omit `kind` or intentionally pass `.browser`.

### Task 2 — Add minimal browser model and URL resolver

**What**

Create browser runtime state and deterministic URL input normalization.

**References**

- New: `supacode/Features/Browser/Models/BrowserSurfaceState.swift`
- New: `supacode/Features/Browser/Models/BrowserURLResolver.swift`
- Tests: new `supacodeTests/BrowserURLResolverTests.swift`
- Inspiration only, do not copy wholesale:
  - `/Users/magimetal/Dev/_third-party/cmux/Sources/Panels/BrowserPanel.swift`
  - `/Users/magimetal/Dev/_third-party/cmux/Sources/Panels/CmuxWebView.swift`

**Implementation details**

- Add `@MainActor @Observable final class BrowserSurfaceState: Identifiable` with:
  - `let id: UUID`
  - `let webView: WKWebView`
  - `var currentURL: URL?`
  - `var pageTitle: String`
  - `var isLoading: Bool`
  - `var estimatedProgress: Double`
  - `var canGoBack: Bool`
  - `var canGoForward: Bool`
  - `func load(_ url: URL)`
  - `func navigateSmart(_ input: String)`
  - `func goBack()`
  - `func goForward()`
  - `func reloadOrStop()`
- Use `import WebKit` directly; no third-party package is expected.
- Use a shared `WKProcessPool`, for example through a private static factory/configuration helper.
- Observe `WKWebView` state needed for the properties above. Keep observers retained and invalidated/deinitialized safely.
- Use `SupaLogger("Browser")` for load/navigation diagnostics. Do not use `print` or `os.Logger`.
- Add `BrowserURLResolver` as a pure, testable type/function. Required behavior:
  - Blank/whitespace input returns `nil`.
  - `https://example.com` resolves unchanged.
  - `example.com` resolves to `https://example.com`.
  - `localhost:3000` resolves to `http://localhost:3000` or `https://localhost:3000`; choose one in code and tests, and document the choice in a code comment.
  - Non-URL search terms resolve to a search URL. Use DuckDuckGo (`https://duckduckgo.com/?q=...`) for this first pass to avoid Google-specific assumptions.

**Acceptance criteria**

- URL resolver tests cover full scheme URL, domain-like input, localhost with port, search terms, and blank input.
- `BrowserSurfaceState` owns exactly one `WKWebView` and exposes only MVP browser state and commands.
- Browser state uses `@Observable`, not `ObservableObject`.

**Guardrails**

- Do not add browser profiles, history suggestions, devtools UI, proxy, importers, storage inspection, or find-in-page.
- Do not make `WKWebView` optional in the model unless a specific compile/runtime issue requires it.
- Do not use `as any`, `@ts-ignore`, `@ts-expect-error`, or analogous type-error suppression.

**Verification**

- `make test` after the full implementation pass.
- Browser resolver tests must be deterministic and not require network access.

### Task 3 — Store and lifecycle browser tabs in `WorktreeTerminalState`

**What**

Add browser tab creation and cleanup without creating terminal split trees for browser tabs.

**References**

- `supacode/Features/Terminal/Models/WorktreeTerminalState.swift`
- `supacode/Features/Terminal/Models/TerminalTabManager.swift`
- Tests: add focused coverage in a new or existing `WorktreeTerminalState` test file if the current test harness can instantiate state with a test `GhosttyRuntime`.

**Implementation details**

- Add storage:
  - `private var browserSurfaces: [TerminalTabID: BrowserSurfaceState] = [:]`
- Add:
  - `@discardableResult func createBrowserTab(initialURL: URL? = nil, focusing: Bool = true) -> TerminalTabID?`
  - `func browserSurface(for tabId: TerminalTabID) -> BrowserSurfaceState?`
  - `func isBrowserTab(_ tabId: TerminalTabID) -> Bool` or equivalent selected-tab helper if needed by views.
- `createBrowserTab(...)` must:
  - Create a tab through `tabManager.createTab(title: "New Browser", icon: "globe", isTitleLocked: false, kind: .browser)`.
  - Create and store `BrowserSurfaceState` keyed by tab ID.
  - Load `initialURL` if non-nil.
  - Update `shouldHideTabBar`.
  - Fire `onTabCreated?()`.
  - Return the new tab ID.
- Update `closeTab(_:)`:
  - If the closing tab is `.browser`, remove `browserSurfaces[tabId]` and do **not** call `removeTree(for:)` for that tab.
  - If the closing tab is `.terminal`, preserve existing terminal cleanup behavior.
  - Preserve existing blocking script cleanup behavior for terminal tabs.
- Update `closeAllSurfaces()` / all-tab cleanup only as needed so browser surfaces are released and tab manager is cleared.
- Update focus helpers so selecting/focusing a browser tab does not call `splitTree(for:)` and does not fabricate a `GhosttySurfaceView`.
  - `focusSelectedTab()` and the private `focusSurface(in:)` path are the risk points.
- Update `captureLayoutSnapshot()` for this first pass:
  - Skip browser tabs with a warning using `layoutLogger`, or skip silently if logging would be noisy.
  - Do not attempt browser persistence in this pass.
  - Terminal snapshots must continue to work.

**Acceptance criteria**

- Creating a browser tab stores `.browser` metadata and a `BrowserSurfaceState`.
- Creating a browser tab does not create an entry in `trees` or `surfaces` for that tab.
- Closing a browser tab removes browser state and uses existing adjacent-tab selection behavior.
- Selecting/focusing a browser tab does not create a terminal surface.
- Terminal tab creation and close behavior remains unchanged.

**Guardrails**

- Do not call `splitTree(for:)` for browser tabs.
- Do not mix browser state into `SplitTree<GhosttySurfaceView>`.
- Do not persist browser tab URL/title in this pass.
- Do not make browser tabs affect terminal busy/task status.

**Verification**

- Add tests where practical for `createBrowserTab` and close behavior. If runtime construction blocks direct state tests, add narrow `#if DEBUG` accessors matching existing test style and test via those.
- `make test` after the full implementation pass.

### Task 4 — Render browser tab UI and WebKit surface

**What**

Branch selected top-level tab rendering between existing terminal split content and new browser content.

**References**

- `supacode/Features/Terminal/Views/WorktreeTerminalTabsView.swift`
- `supacode/Features/Terminal/TabBar/Views/TerminalTabContentStack.swift`
- New: `supacode/Features/Browser/Views/BrowserTabView.swift`
- New: `supacode/Features/Browser/Views/BrowserWebViewRepresentable.swift`

**Implementation details**

- In `WorktreeTerminalTabsView`, when rendering `TerminalTabContentStack`, inspect the selected/tab content kind.
- For `.terminal`, keep the existing `TerminalSplitTreeAXContainer(tree: state.splitTree(for: tabId), ...)` path.
- For `.browser`, render `BrowserTabView(surface: browserSurface)` and never call `state.splitTree(for:)`.
- `BrowserTabView` must include compact chrome:
  - Back button.
  - Forward button.
  - Reload/stop button.
  - URL/search text field.
  - Minimal loading/progress indication if available from `estimatedProgress` / `isLoading`.
- `BrowserWebViewRepresentable` should wrap the model-owned `WKWebView` for SwiftUI/AppKit hosting.
- Add `.help(...)` tooltips to browser chrome buttons.
- Empty/error fallback: if a browser tab is selected but `browserSurface(for:)` returns nil, render a small non-crashing placeholder such as `Text("Browser unavailable")` and log once if feasible.
- Page title updates:
  - Add a callback or lightweight binding from `BrowserSurfaceState` to update the tab title when `pageTitle` or `currentURL` changes.
  - Fallback order: non-empty page title, host, absolute URL string, `New Browser`.

**Acceptance criteria**

- Browser tabs render browser chrome and a WebKit surface, not a terminal split.
- Terminal tabs still render `TerminalSplitTreeAXContainer` exactly as before.
- Browser back/forward buttons reflect `canGoBack` / `canGoForward`.
- Reload button stops loading when `isLoading == true`, otherwise reloads.
- URL field loads through `BrowserURLResolver`.
- Browser tab title changes from loaded page metadata without breaking terminal title updates.

**Guardrails**

- Do not subclass `WKWebView` unless native behavior blocks required shortcuts during verification.
- Do not add split controls for browser content in this pass.
- Do not create a separate full browser product shell.

**Verification**

- Manual UI checks after build:
  - Create a terminal tab.
  - Create a browser tab.
  - Confirm browser tab has chrome and terminal tab has terminal content.
  - Load `https://example.com`.
  - Navigate to a second URL and verify back/forward/reload state.
  - Close browser tab and verify terminal tab still works.

### Task 5 — Add New Browser Tab command routing

**What**

Expose browser tab creation through the same app/focused command architecture as terminal tab creation.

**References**

- `supacode/Clients/Terminal/TerminalClient.swift`
- `supacode/Features/Terminal/BusinessLogic/WorktreeTerminalManager.swift`
- `supacode/Features/App/Reducer/AppFeature.swift`
- `supacode/Commands/TerminalCommands.swift` or new `supacode/Commands/BrowserCommands.swift`
- `supacode/Features/Repositories/Views/WorktreeDetailView.swift`
- Tests:
  - Add to `supacodeTests/AppFeatureTerminalSetupScriptTests.swift` or create `supacodeTests/AppFeatureBrowserTabTests.swift`.

**Implementation details**

- Add `TerminalClient.Command.createBrowserTab(Worktree, initialURL: URL? = nil)`.
- Handle it in `WorktreeTerminalManager.handleTabCommand(_:)` by calling `state(for: worktree).createBrowserTab(initialURL:)`.
- Update exhaustive switch lists in `handleSearchCommand(_:)` and `handleBindingActionCommand(_:)` so `.createBrowserTab` is categorized correctly.
- Add `AppFeature.Action.newBrowserTab`.
- Reducer behavior should mirror `.newTerminal` selection guard, except:
  - Do not consume setup scripts.
  - Send `.createBrowserTab(worktree, initialURL: nil)`.
  - Optional analytics event name: `browser_tab_created`.
- Add focused value `newBrowserTabAction`.
- Wire focused action in `WorktreeDetailView` next to `newTerminalAction`.
- Add menu item **New Browser Tab**.
  - No keyboard shortcut in this first pass unless an existing project shortcut exists and does not conflict.
  - Disabled when no worktree is active, matching `newTerminalAction` behavior.

**Acceptance criteria**

- With an active worktree, **New Browser Tab** is enabled and creates/selects a browser tab.
- With no active worktree, **New Browser Tab** is disabled/no-op.
- `.newBrowserTab` reducer test proves `.createBrowserTab` is sent only when a selected worktree exists.
- `.newTerminal` setup-script behavior remains unchanged.

**Guardrails**

- Do not steal Ghostty `new_tab` shortcut.
- Do not overload terminal search or split commands for browser behavior.
- Do not add command-palette entries unless implementation finds an existing simple pattern and can do it without scope expansion.

**Verification**

- Add reducer tests for selected and unselected worktree cases.
- Manual menu enabled/disabled check after build.

### Task 6 — Verification and implementation handoff

**What**

Finish the code implementation pass with objective build/test evidence, live browser behavior evidence, and a clean implementation handoff.

**References**

- `Makefile`
- Files touched by Tasks 1–5.
- `AGENTS.md`

**Required commands after implementation**

Run from repo root, with `make build-app` required at minimum before handoff:

1. `make build-app`
2. `make test` if tests were added/changed or if related test coverage is practical for the touched code.
3. `make lint` if Swift files were added/changed.

If formatting changes are needed, run `make check` only after deciding whether automatic formatting is acceptable for the touched files. If `make check` modifies files, re-read the modified files and re-run relevant verification.

**Manual browser checks after `make build-app` succeeds**

- Launch the app with `make run-app` or from Xcode if preferred.
- Select a worktree.
- Create **New Terminal** and verify terminal behavior still works.
- Create **New Browser Tab**.
- Load `https://example.com`.
- Load a second URL or search term.
- Verify back, forward, reload/stop, title update, tab switching, and browser tab close.
- Verify terminal split/new tab/close tab still work after browser tab use.

**Acceptance criteria**

- `make build-app` passes, or failure is documented with exact output and a scoped fix recommendation.
- `make test` and `make lint` pass when run, or skipped/failed commands are documented with exact reasons and scoped follow-up.
- Manual browser check passes for top-level browser tabs, or any blocker is documented with exact reproduction details.

**Guardrails**

- Do not hide failures.
- Do not claim browser behavior was verified without a live/manual check.
- Do not include persistence or mixed split work to make manual checks pass.

## Operational Preflight, Closure, and Verification Handoff

These repository operations are required by `AGENTS.md` for implementation execution, but they are not product acceptance criteria for embedded browser tabs.

### Operational preflight before coding

- Check the current git branch name before implementation work starts.
  - If the branch is `main`, do not rename it.
  - If the branch is a generic branch name such as an animal name, rename it to a task-appropriate branch before coding.
- Inspect `git status --short` before coding and note any pre-existing unrelated changes so implementation does not overwrite or commit them.

### Operational closure after implementation verification

- Ensure `make build-app` has been run from the repo root before handoff, even if other verification commands already passed.
- Run `git status --short` and review the exact touched files before staging.
- Commit only the implementation changes owned by this pass after successful verification.
  - Stage explicit file paths only.
  - Do not use `git add .`.
  - Do not include unrelated working tree changes.
- If the current branch is not `main` and Tasks 1–6 have been implemented, open a PR for the branch.
- If any required command fails, either fix within this plan scope or report the exact failing command/output and stop before committing.

### Final implementation response handoff

Include:

- What changed.
- Where it changed.
- Automated command results with actual pass/fail status, including `make build-app`.
- Manual browser checks performed.
- `git status --short` summary confirming only expected implementation files remain changed, or listing known unrelated pre-existing changes.
- Commit hash or explicit reason no commit was created.
- PR link or explicit reason no PR was opened.
- Known unverified items or blockers.

## Deferred Follow-Up Work

- Browser tab persistence and restore through a compatible `TerminalLayoutSnapshot` migration.
- Mixed terminal/browser split leaves with a generic surface abstraction replacing `SplitTree<GhosttySurfaceView>`.
- Browser find-in-page and richer keyboard/focus behavior if native `WKWebView` conflicts with app shortcuts.
- Browser session/privacy policy decisions: app-global persistent WebKit store vs per-worktree/profile/ephemeral storage.
- Command palette entry for **New Browser Tab** if product wants it.

## Key Assumptions

- WebKit can be imported directly by the macOS app target.
- First pass can skip browser tab persistence while still satisfying the PRD/ADR MVP direction for top-level browser tabs.
- Browser tabs are scoped to the selected worktree, matching current terminal tab ownership.
- Existing `WorktreeTerminalManager` / `WorktreeTerminalState` remain the runtime owner for MVP despite naming debt.
- `make build-app` is the minimum required implementation handoff command; `make test` and `make lint` should run when appropriate for the touched code and test/lint surface.

## Open Risks / Unknowns

- `WKWebView` may consume keyboard shortcuts needed by Supacode; only live UI verification can confirm whether a subclass is needed.
- Direct unit testing of `WorktreeTerminalState` browser side effects may require existing runtime test helpers or narrow debug accessors.
- Skipping browser persistence means browser tabs may not survive app restart in this first pass; this is deliberate to keep the first coding pass bounded.
- Browser cookies/session data will use WebKit defaults unless a later PRD/ADR update specifies isolation.

## Self-Review

- The plan is limited to top-level browser tabs and explicitly excludes mixed splits and persistence.
- Each task includes exact files/symbols, acceptance criteria, guardrails, and verification.
- The plan keeps PRD/ADR references and follows ADR-0001 Option A.
- No production code changes are included in this plan artifact.
