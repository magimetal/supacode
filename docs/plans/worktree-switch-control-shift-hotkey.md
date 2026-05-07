# Worktree Switch Control+Shift Hotkey Implementation Plan

## Objective

Change direct worktree selection from plain Control+number to Control+Shift+number for worktree slots 1-10, while preserving Command+number terminal tab switching and Command-held tab/UI hints.

## Context and Evidence

- PRD: `docs/prd/0004-worktree-switch-hotkey-modifier.md`
- Shortcut definitions: `SupacodeSettingsShared/App/AppShortcuts.swift`
  - `selectWorktree1` ... `selectWorktree0` currently use `modifiers: [.control]`.
  - `AppShortcuts.worktreeSelection` feeds command registration and sidebar hint text.
  - `AppShortcuts.tabSelectionGhosttyKeybindArguments` still defines Ghostty tab selection as `ctrl+number` / `ctrl+digit_*`, while tab UI hints are hard-coded as `⌘number`; preserve the existing tab behavior and do not change this path unless implementation discovers a separate product mismatch.
- Worktree command registration: `supacode/Commands/WorktreeCommands.swift`
  - `worktreeShortcuts(from:)` maps `AppShortcuts.worktreeSelection` through user overrides and registers menu shortcuts via `.appKeyboardShortcut(shortcut)`.
- Shortcut hint observer: `supacode/App/CommandKeyObserver.swift`
  - Single `isPressed` boolean currently becomes true for Command or Control.
  - This boolean is shared by sidebar worktree hints, terminal tab hints, terminal tab accessory hints, pull request status details, and worktree detail action hints.
- Sidebar hints: `supacode/Features/Repositories/Views/SidebarItemsView.swift`
  - Uses `commandKeyObserver.isPressed` to decide whether to map visible `hotkeyRows` to `AppShortcuts.worktreeSelection` hints.
  - Hint text already comes from effective shortcuts, preserving enabled custom overrides and disabled shortcuts.
- Terminal tab hints: `supacode/Features/Terminal/TabBar/Views/TerminalTabView.swift`
  - Displays hard-coded `⌘1` ... `⌘9` and gates visibility on `commandKeyObserver.isPressed`.
- Tests:
  - `supacodeTests/AppShortcutsTests.swift` currently asserts worktree shortcuts are `⌃1` ... `⌃0` with `.control` modifiers.
  - `supacodeTests/CommandKeyObserverTests.swift` currently asserts shortcut hints appear for Command or Control.
- Version/release points:
  - Version state is in `Configurations/Project.xcconfig` (`MARKETING_VERSION = 0.9.4`, `CURRENT_PROJECT_VERSION = 140` observed during planning).
  - Unsigned fork release flow is documented by `.agents/skills/releasing-fork-unsigned/SKILL.md` and `Makefile` targets including `make bump-version` and `make build-app`.

## Chosen Chord Rationale

Use Control+Shift+number.

- Keeps worktree switching close to the previous Control+number mental model.
- Avoids plain Control conflicts with shells, editors, multiplexers, and TUIs.
- Avoids Command+Shift+3/4/5 screenshot conflicts.
- Avoids Option/Alt number text-input and terminal Meta behavior.

## Task 1 — Update default worktree selection shortcut definitions

### What

Change all direct worktree selection defaults from `.control` to `[.control, .shift]`.

### References

- `SupacodeSettingsShared/App/AppShortcuts.swift`
  - `AppShortcuts.selectWorktree1`
  - `AppShortcuts.selectWorktree2`
  - `AppShortcuts.selectWorktree3`
  - `AppShortcuts.selectWorktree4`
  - `AppShortcuts.selectWorktree5`
  - `AppShortcuts.selectWorktree6`
  - `AppShortcuts.selectWorktree7`
  - `AppShortcuts.selectWorktree8`
  - `AppShortcuts.selectWorktree9`
  - `AppShortcuts.selectWorktree0`
  - `AppShortcuts.worktreeSelection`

### Acceptance Criteria

- `AppShortcuts.worktreeSelection.map(\.display)` resolves to `⌃⇧1` ... `⌃⇧0`.
- Every default `AppShortcuts.worktreeSelection` shortcut has both `.control` and `.shift` modifiers.
- No default direct worktree selection shortcut remains plain `.control`.
- Existing override behavior remains unchanged: user overrides still replace defaults through `effective(from:)`; disabled overrides still return `nil`.

### Guardrails

- Do not change `AppShortcutID` stable keys; persisted override keys must remain `selectWorktree1` ... `selectWorktree0`.
- Do not change worktree ordering or the `1`-`9`, `0` slot mapping.
- Do not modify `AppShortcuts.tabSelectionGhosttyKeybindArguments` in this task.
- Do not edit generated `supacode.xcodeproj` or `supacode.xcworkspace`.

### Verification

- Update and later run:
  ```bash
  xcodebuild test -workspace supacode.xcworkspace -scheme supacode -destination "platform=macOS" \
    -only-testing:supacodeTests/AppShortcutsTests \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" -skipMacroValidation -parallel-testing-enabled NO
  ```

## Task 2 — Split shortcut hint modifier state by surface

### What

Replace the single Command-or-Control hint gate with distinct observer state so Command-held UI remains Command-specific and worktree sidebar hints use the new Control+Shift chord.

Recommended minimal shape:

- Keep `CommandKeyObserver.isPressed` as the Command-held hint flag for existing call sites.
- Add `CommandKeyObserver.isWorktreeSelectionPressed` for Control+Shift-held sidebar hints.
- Replace `shouldShowShortcuts(for:)` with or supplement it using focused helpers, for example:
  - `shouldShowCommandShortcuts(for:) -> Bool` returns true for `.command`.
  - `shouldShowWorktreeSelectionShortcuts(for:) -> Bool` returns true for Control+Shift without plain Control alone.
- Preserve the existing 300 ms hold delay for both states.
- On app resign active, clear both states.

### References

- `supacode/App/CommandKeyObserver.swift`
- Existing consumers of `commandKeyObserver.isPressed`:
  - `supacode/Features/Terminal/TabBar/Views/TerminalTabView.swift`
  - `supacode/Features/Terminal/TabBar/Views/TerminalTabBarTrailingAccessories.swift`
  - `supacode/Features/Repositories/Views/WorktreeDetailView.swift`
  - `supacode/Features/Repositories/Views/PullRequestStatusButton.swift`
  - `supacode/Features/Repositories/Views/SidebarItemsView.swift`

### Acceptance Criteria

- Holding Command still enables existing Command-oriented hints, including terminal tab hints.
- Holding plain Control does not enable sidebar worktree shortcut hints.
- Holding Control+Shift enables sidebar worktree shortcut hints after the existing delay.
- Holding Control+Shift does not cause terminal tab hints to imply Command+number tab switching.
- State resets when the app resigns active.

### Guardrails

- Do not rename `CommandKeyObserver` broadly unless required by the compiler; keep the diff small.
- Do not add a new dependency client for modifier state.
- Do not remove the existing hold delay behavior.
- Do not couple terminal tab hint visibility to worktree hint visibility.

### Verification

- Update and later run:
  ```bash
  xcodebuild test -workspace supacode.xcworkspace -scheme supacode -destination "platform=macOS" \
    -only-testing:supacodeTests/CommandKeyObserverTests \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" -skipMacroValidation -parallel-testing-enabled NO
  ```

## Task 3 — Point sidebar worktree hints at the new worktree hint state

### What

Use the new worktree-specific observer property for sidebar hotkey hints.

### References

- `supacode/Features/Repositories/Views/SidebarItemsView.swift`
  - Replace `let showShortcutHints = commandKeyObserver.isPressed` with the worktree-specific property from Task 2.
  - Keep `shortcutHint(for:)` resolving `AppShortcuts.worktreeSelection[index].effective(from: overrides)?.display`.

### Acceptance Criteria

- Sidebar hint text is still derived from effective shortcuts, including user overrides and disabled shortcuts.
- Default sidebar hints display `⌃⇧1` ... `⌃⇧0` when Control+Shift is held.
- Sidebar hints do not display when only Control is held.
- The visible row-to-hotkey index mapping remains based on `hotkeyRows.enumerated()` and is not changed.

### Guardrails

- Do not alter sidebar section ordering, pinned/unpinned movement, row selection, or worktree selection reducer actions.
- Do not special-case only default shortcuts in the display path; keep override resolution central.

### Verification

- Covered by `CommandKeyObserverTests` and `AppShortcutsTests` plus manual QA in Task 6.

## Task 4 — Preserve worktree command registration and override behavior

### What

Verify that command registration continues to flow through `AppShortcuts.worktreeSelection` and user overrides. Code changes are likely unnecessary beyond Task 1 because `WorktreeCommands` already registers effective shortcuts.

### References

- `supacode/Commands/WorktreeCommands.swift`
  - `worktreeShortcuts(from:)`
  - `WorktreeShortcutButton.body`
- `SupacodeSettingsShared/App/AppShortcuts.swift`
  - `AppShortcut.effective(from:)`
  - `View.appKeyboardShortcut(_:)`

### Acceptance Criteria

- Default command registration uses Control+Shift+number through `AppShortcuts.worktreeSelection`.
- A custom override still changes both the registered shortcut and displayed sidebar hint text.
- A disabled override still prevents the shortcut registration and hides that row's sidebar hint text.

### Guardrails

- Do not bypass `.appKeyboardShortcut(shortcut)` with ad hoc event monitors.
- Do not implement migration of existing user overrides unless explicitly requested; PRD leaves migration as an open question.
- Do not change command palette or worktree history shortcuts.

### Verification

- Covered by focused `AppShortcutsTests` and manual override QA in Task 7.

## Task 5 — Update automated tests

### What

Update focused tests to encode the new shortcut contract.

### References

- `supacodeTests/AppShortcutsTests.swift`
  - Rename `worktreeSelectionUsesControlNumberShortcuts` to `worktreeSelectionUsesControlShiftNumberShortcuts`.
  - Expected displays: `⌃⇧1` ... `⌃⇧0`.
  - Assert each shortcut contains `.control` and `.shift` and does not equal plain `.control`.
  - Keep `tabSelectionGhosttyKeybindArgumentsMatchExpected` unchanged.
  - Keep `ghosttyCLIArgumentsKeepWorktreeUnbindsAndTabBinds`; update any assumptions if unbind strings now include `ctrl+shift+digit_*`.
- `supacodeTests/CommandKeyObserverTests.swift`
  - Replace Command-or-Control expectations with Command-only expectations for `isPressed`/command helper.
  - Add Control+Shift expectations for the new worktree helper.
  - Assert plain Control is false for worktree hints.
  - Assert Command remains true for Command hints and false for worktree hints unless the helper intentionally treats combined modifiers differently.

### Acceptance Criteria

- Tests fail before implementation for the expected reasons: old `.control` defaults and old plain-Control hint gate.
- Tests pass after implementation.
- Tab-selection tests remain unchanged and passing.

### Guardrails

- Do not weaken assertions to only check non-nil shortcut existence.
- Do not use `Task.sleep` in tests.
- Do not hide compiler or test failures.

### Verification

- Focused tests:
  ```bash
  xcodebuild test -workspace supacode.xcworkspace -scheme supacode -destination "platform=macOS" \
    -only-testing:supacodeTests/AppShortcutsTests \
    -only-testing:supacodeTests/CommandKeyObserverTests \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" -skipMacroValidation -parallel-testing-enabled NO
  ```
- Full relevant checks before release readiness:
  ```bash
  make test
  make lint
  make build-app
  ```

## Task 6 — Manual QA for shortcut and hint behavior

### What

After implementation, validate in the running macOS app.

### References

- Running app built from `make build-app` / local Debug product.
- Settings UI: `supacode/Features/Settings/Views/KeyboardShortcutsSettingsView.swift`
- Sidebar and tabs:
  - `supacode/Features/Repositories/Views/SidebarItemsView.swift`
  - `supacode/Features/Terminal/TabBar/Views/TerminalTabView.swift`

### Acceptance Criteria

- With multiple visible worktrees, Control+Shift+1 through Control+Shift+0 switches to the expected sidebar worktree slot.
- Plain Control+1 through Control+0 does not switch worktrees in default settings.
- Holding Control alone does not show sidebar worktree hints.
- Holding Control+Shift shows sidebar hints as `⌃⇧1` ... `⌃⇧0`.
- Command+1 through Command+9 tab switching still works exactly as before.
- Holding Command shows tab hints as `⌘1` ... `⌘9`.
- Holding Control+Shift does not show tab hints.
- Configure one worktree shortcut override in Settings > Shortcuts; verify the menu shortcut and sidebar hint text use the override.
- Disable one worktree shortcut in Settings > Shortcuts; verify its menu shortcut is absent and sidebar hint text for that slot is hidden.

### Guardrails

- Do not mutate `ThirdParty/ghostty` or `Resources/git-wt` during QA.
- Do not use generated project edits to make QA pass.

### Verification

- Record manual QA results in the implementation final response and release notes draft.

## Task 7 — Release readiness and fork release sequence

### What

After implementation and verification pass, prepare the fork release using the unsigned local build flow.

### References

- `Configurations/Project.xcconfig`
- `Makefile`
  - `make bump-version`
  - `make build-app`
- `.agents/skills/releasing-fork-unsigned/SKILL.md`

### Acceptance Criteria

- Version bump is committed/tagged after the hotkey implementation is complete and verified.
- Release notes mention the worktree shortcut change as a terminal-compatibility shortcut update and explicitly state the new default `Control+Shift+number` chord.
- GitHub release contains both unsigned zip and sha256 assets with the required names:
  - `Supacode-{MARKETING_VERSION}-build-{CURRENT_PROJECT_VERSION}-local-unsigned.zip`
  - `Supacode-{MARKETING_VERSION}-build-{CURRENT_PROJECT_VERSION}-local-unsigned.zip.sha256`

### Guardrails

- Do not run release steps until implementation, tests, lint, build, and manual QA are complete.
- Confirm branch is `main` and working tree contains only intentional changes before bumping version.
- Do not use `make archive` for the unsigned fork release.
- Do not include unrelated local changes in the version bump commit.

### Verification / Release Commands

```bash
git status --short
git branch --show-current
make test
make lint
make build-app
make bump-version
git push origin main --follow-tags
make build-app
settings=$(xcodebuild -workspace supacode.xcworkspace -scheme supacode -configuration Debug -showBuildSettings -json 2>/dev/null)
build_dir=$(echo "$settings" | jq -r '.[0].buildSettings.BUILT_PRODUCTS_DIR')
product=$(echo "$settings" | jq -r '.[0].buildSettings.FULL_PRODUCT_NAME')
app_path="$build_dir/$product"
test -d "$app_path"
version=$(awk -F' = ' '/^MARKETING_VERSION = /{print $2}' Configurations/Project.xcconfig)
build=$(awk -F' = ' '/^CURRENT_PROJECT_VERSION = /{print $2}' Configurations/Project.xcconfig)
mkdir -p build
zip_name="Supacode-${version}-build-${build}-local-unsigned.zip"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "build/$zip_name"
(cd build && shasum -a 256 "$zip_name" > "$zip_name.sha256")
prev_tag=$(gh release view --repo magimetal/supacode --json tagName -q .tagName)
notes_file=$(mktemp)
gh api "repos/magimetal/supacode/releases/generate-notes" \
  -f tag_name="v${version}" \
  -f previous_tag_name="$prev_tag" \
  --jq '.body' > "$notes_file"
# Edit $notes_file to mention Control+Shift+number and include unsigned Gatekeeper note.
gh release create "v${version}" \
  --repo magimetal/supacode \
  --title "Supacode ${version} build ${build}" \
  --notes-file "$notes_file" \
  "build/${zip_name}" "build/${zip_name}.sha256"
gh release view "v${version}" --repo magimetal/supacode --json assets --jq '.assets[].name'
```

## Risks / Unknowns

- **Observed:** `CommandKeyObserver.isPressed` is shared by several hint surfaces. A naive change from Command-or-Control to Command-or-Control+Shift would still show tab hints under Control+Shift. Split state avoids that.
- **Observed:** Tests currently encode the old Control+number contract and must be updated.
- **Observed:** Tab UI hints show `⌘number`, but `AppShortcuts.tabSelectionGhosttyKeybindArguments` uses Ghostty `ctrl+number` bindings. This plan preserves that existing path and validates user-visible tab behavior manually rather than broadening scope.
- **Inferred:** SwiftUI menu shortcut registration should accept `[.control, .shift]` for number keys because the project already registers multi-modifier shortcuts elsewhere.
- **Unknown:** Existing users with persisted plain-Control overrides will keep those explicit overrides unless migration is requested. This preserves override behavior but may leave some users on the old chord by choice or legacy config.
- **Unknown:** Exact AppKit matching behavior for extra modifiers on Control+Shift+number should be manually checked; tests cover definitions, not runtime event dispatch.
