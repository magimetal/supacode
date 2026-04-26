---
name: developing-supacode
description: Use when implementing, reviewing, or planning changes in the Supacode macOS Swift/TCA app. Covers repo architecture, TCA/Observable/GhosttyKit/WebKit lessons, build-toolchain pitfalls, documentation lifecycle, verification, and commit hygiene.
---

# Developing Supacode

## When to Use

Use this skill for Supacode repo work involving:

- Swift/TCA app features, reducers, views, tests, settings, commands, or clients.
- Terminal surfaces, GhosttyKit integration, tab/split/pane behavior, or keybindings.
- Embedded browser tabs or browser panes backed by WebKit/WKWebView.
- Build failures involving Xcode, Metal tools, Zig, GhosttyKit, Tuist/project generation, or mise.
- PRD/ADR/plan authoring, implementation follow-through, completion, or review.

Do not use this skill for unrelated Swift apps. Supacode has local constraints. Cute, but binding.

## Repository Ground Truth

Read before changing behavior:

- `AGENTS.md` for current commands, architecture, coding rules, and app-specific standards.
- `docs/prd/README.md`, `docs/adr/README.md`, and `docs/plans/` for product intent and accepted decisions.
- Existing nearby tests before adding new patterns.
- Existing clients/reducers before introducing a new dependency boundary.

Key architecture touchpoints:

- Root TCA store: `AppFeature`.
- Worktree/app surfaces: `WorktreeTerminalManager`, `WorktreeTerminalState`, `TerminalTabManager`.
- Terminal runtime: `GhosttyRuntime`, `GhosttySurfaceView`, `GhosttySurfaceBridge`, `GhosttyKit`.
- Browser runtime: WebKit/WKWebView state such as `BrowserSurfaceState` and browser surface/pane views.
- Command routing: app menu/commands, command palette, reducer actions, and `TerminalClient` events.
- Settings/state sharing: prefer direct `@Shared` in reducers when appropriate; do not add clients only to wrap shared settings.

## Core Implementation Rules

- Use TCA for app state, actions, side effects, and testable reducer behavior.
- Use `@ObservableState` for TCA feature state.
- Use `@MainActor @Observable` for non-TCA shared runtime stores.
- Never introduce `ObservableObject` for new app models.
- Do not mutate `store.*` directly in SwiftUI views; send actions.
- Use `SupaLogger`; never use `print()` or direct `os.Logger` in app code.
- Add or update reducer tests when reducer logic changes.
- In tests, do not use `Task.sleep`; use `TestClock` or an injected clock and advance it.
- Keep changes tightly scoped; avoid broad `Terminal*` renames unless the task explicitly requires them.

## Terminal, GhosttyKit, and Browser Lessons

### Terminal and Ghostty

- Ghostty owns terminal keybinding interpretation. Route Ghostty-bound keys through runtime action callbacks such as `GHOSTTY_ACTION_NEW_TAB` / `GHOSTTY_ACTION_CLOSE_TAB` instead of duplicating them as app shortcuts.
- `GhosttySurfaceView.performKeyEquivalent` should let Ghostty handle bound keys first; only unbound keys fall through to the app.
- Avoid sending terminal-only commands to browser panes or other non-terminal surfaces.
- Do not create placeholder terminal surfaces when the intended content is a browser pane.

### Browser tabs and panes

- Browser support uses platform WebKit/WKWebView, not a third-party browser runtime.
- Browser state should own WebKit lifecycle, navigation state, title updates, and shared process-pool behavior.
- Current accepted direction supports heterogeneous split leaves: terminal and browser content can coexist in one split layout.
- Keep terminal-only layout restore compatible. Do not synthesize unwanted browser or terminal panes during restore.
- Browser-pane MVP boundaries: no browser persistence, profiles, devtools UI, proxy controls, history suggestions, storage inspection, or cmux-scale extras unless a PRD/ADR says otherwise.

### Context menu and command routing

- Ghostty/AppKit right-click handling can swallow SwiftUI context menus inside terminal content.
- For terminal-pane actions that must work reliably, prefer app-level commands, focused actions, command palette entries, or hotkeys over relying solely on SwiftUI context menus inside Ghostty views.
- Validate command eligibility by focused surface kind: terminal commands for terminal leaves, browser commands for browser leaves.

## Toolchain and Build Pitfalls

- Target macOS 26.0+ and Swift 6.0 unless project files say otherwise.
- Xcode 26.4 compatibility can expose stricter Swift, linker, Metal, and package behavior. Treat toolchain errors as first-class evidence, not noise.
- GhosttyKit is built from `ThirdParty/ghostty` into `Frameworks/GhosttyKit.xcframework`; symbol/link failures often mean the framework or resource bundle is stale or built with the wrong toolchain.
- Use mise-managed tools where the repo expects them, especially Zig, SwiftLint, and related build tools.
- Zig may require the patched Homebrew/mise path used by this repo. Do not assume system Zig is correct.
- Ghostty standalone app artifacts are not the product here; skip or avoid standalone Ghostty app build paths unless the task explicitly targets them.
- Metal toolchain failures can come from missing/changed Xcode Metal utilities. Verify selected Xcode and tool paths before changing app code.
- If GhosttyKit symbols are missing, inspect build scripts, xcframework slices, exported headers/modules, and linkage settings before adding Swift workarounds.

## Documentation Lifecycle

Use docs to constrain scope before implementation when features or architecture change:

- PRD: product requirement, user value, scope, acceptance criteria.
- ADR: accepted architectural decision, alternatives, consequences, and guardrails.
- Plan: executable implementation sequence with references, acceptance criteria, guardrails, and verification.

Lifecycle rules:

- Cross-link related PRDs, ADRs, and plans.
- Keep ADR supersession chains explicit when decisions change.
- Mark PRDs/plans complete only after implementation and verification evidence exist.
- Update README index tables when adding or changing PRD/ADR status.
- Do not let implementation drift beyond the accepted PRD/ADR without updating the docs or asking for direction.

## Verification Commands

Default repo checks:

```bash
make test
make build-app
make lint
```

Use focused checks first when iterating, then run the relevant full checks before claiming completion. Examples:

```bash
xcodebuild test -project supacode.xcodeproj -scheme supacode -destination "platform=macOS" \
  -only-testing:supacodeTests/SomeTests \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" -skipMacroValidation
```

For docs-only or skill-only changes, do not run build/test/lint unless requested. Re-read changed files and inspect `git diff` instead.

## Commit Hygiene

- Check `git status --short` before staging.
- Stage explicit paths only. Never use `git add .` or `git add -A` for normal task commits.
- Commit only files relevant to the requested change.
- Do not commit unrelated local changes.
- Do not open a PR from `main` unless explicitly requested.
- Include verification evidence in the final response.

Recommended staging pattern:

```bash
git add path/to/file1 path/to/file2
git diff --cached --stat
git commit -m "type: concise summary"
```

## Practical Checklist

Before implementation:

- [ ] Read `AGENTS.md` and relevant docs/tests.
- [ ] Identify whether the change is TCA state, runtime `@Observable`, GhosttyKit, WebKit, settings, commands, or docs.
- [ ] Confirm accepted PRD/ADR/plan boundaries for feature or architecture work.
- [ ] Search for similar existing implementation before adding helpers.

During implementation:

- [ ] Keep reducers testable and side effects injected.
- [ ] Keep runtime stores `@MainActor @Observable`.
- [ ] Preserve terminal behavior when adding browser or pane behavior.
- [ ] Gate commands by focused surface/content kind.
- [ ] Use app-level commands/hotkeys when Ghostty/AppKit can intercept local menus.

Before final response:

- [ ] Re-read modified files.
- [ ] Run relevant verification, or state why a check was intentionally skipped.
- [ ] Inspect `git diff` and `git status --short`.
- [ ] Stage explicit paths only if committing.
- [ ] Report what changed, where, command results, and remaining unverified areas.
