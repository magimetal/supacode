<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# PROJECT KNOWLEDGE BASE: `supacode/`

## OVERVIEW
Main app target. Contains SwiftUI app composition, TCA features/clients, terminal infrastructure, app commands, domain models, support views/utilities, and resources.

## STRUCTURE
```
supacode/
├── App/             # app delegate, composition root, reference views, window helpers
├── Clients/         # dependency clients used by reducers
├── Commands/        # SwiftUI command menus
├── Domain/          # Repository/Worktree/sidebar/deeplink value types
├── Features/        # TCA features + terminal Observable models
├── Infrastructure/  # Ghostty integration and hook socket server
├── Support/         # small UI/util helpers and logging support
└── Resources/       # themes/assets consumed at runtime
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Boot wiring | `App/supacodeApp.swift` | Instantiates managers and injects dependencies. |
| App-wide effects | `Features/App/Reducer/AppFeature.swift` | Deeplinks, lifecycle, terminal/worktree event subscriptions. |
| Dependency clients | `Clients/*` | Live/test dependencies for TCA. |
| Git/worktree domain | `Domain/Repository.swift`, `Domain/Worktree*.swift` | Folder and git repo modeling. |
| Terminal integration | `Features/Terminal/`, `Infrastructure/Ghostty/` | Split/tab state plus Ghostty C bridge. |

## CONVENTIONS
- Keep UI mutations action-driven; views send actions, reducers mutate state.
- `@Observable` managers live outside TCA only when long-lived runtime state is not reducer state.
- Prefer Swift-native APIs where present (`replacing()`, not `replacingOccurrences()`).
- Use `SupaLogger` for diagnostics.

## ANTI-PATTERNS
- No `ObservableObject` introductions.
- No NSNotification reducer communication.
- No app-specific menu shortcut path for Ghostty-owned keybindings.
