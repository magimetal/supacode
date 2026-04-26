<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# PROJECT KNOWLEDGE BASE: `supacode/Infrastructure/Ghostty/`

## OVERVIEW
Swift bridge for GhosttyKit/libghostty: runtime creation, surface lifecycle, callbacks, SwiftUI hosting views, search, shortcut mapping, and secure input.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Shared runtime | `GhosttyRuntime.swift` | Owns `ghostty_app_t`, callback registration, app-level actions. |
| Surface bridge | `GhosttySurfaceBridge.swift` | Swift object wrapping a Ghostty surface. |
| SwiftUI/NSView host | `GhosttySurfaceView.swift`, `GhosttyTerminalView.swift` | Rendering, focus, key routing, lifecycle. |
| Surface state | `GhosttySurfaceState.swift` | Observable Swift-side metadata. |
| Keybindings | `GhosttyShortcutManager.swift`, `GhosttyCommand.swift` | User overrides → Ghostty CLI args/actions. |
| Search/splits | `GhosttySearchNavigation.swift`, `GhosttySplitAction.swift` | Higher-level terminal commands. |

## CONVENTIONS
- Ghostty keybindings win before app shortcuts; `performKeyEquivalent` routes bound keys to Ghostty first.
- Tab open/close comes from Ghostty actions (`GHOSTTY_ACTION_NEW_TAB`, `GHOSTTY_ACTION_CLOSE_TAB`).
- Build GhosttyKit via `make build-ghostty-xcframework` / `scripts/build-ghostty.sh` when libghostty source changes.

## ANTI-PATTERNS
- Do not create a second `ghostty_app_t` runtime per surface.
- Do not directly call app menu tab logic for Ghostty-owned bindings.
- Do not edit generated `.build/ghostty` artifacts as source.
