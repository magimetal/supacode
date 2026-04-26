<!--THIS IS A GENERATED FILE - DO NOT MODIFY DIRECTLY, FOR MANUAL ADJUSTMENTS UPDATE `AGENTS_CUSTOM.MD`-->
# PROJECT KNOWLEDGE BASE: `supacode-cli/`

## OVERVIEW
Bundled command-line client installed/copied into app resources. Parses commands, resolves IDs/defaults, then dispatches to the running app via socket or deeplink URL.

## STRUCTURE
```
supacode-cli/
├── SupacodeCLI.swift   # ArgumentParser entry point
├── Commands/           # open/repo/settings/socket/surface/tab/worktree commands
├── Helpers/            # ID resolution, formatting, env defaults, URL builders
└── Transport/          # socket discovery/client and deeplink/query dispatchers
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add command | `Commands/*Command.swift`, `SupacodeCLI.swift` | Wire with ArgumentParser subcommands. |
| Deep link construction | `Helpers/DeeplinkURLBuilder.swift` | Keep app reducer URL parsing in sync. |
| Socket transport | `Transport/SocketClient.swift`, `SocketDiscovery.swift` | Talks to app hook/socket server. |
| Worktree commands | `Commands/WorktreeCommand.swift`, `WorktreeScriptCommand.swift` | Repo/worktree ID resolution. |

## CONVENTIONS
- CLI target has `PRODUCT_NAME = supacode`, `PRODUCT_MODULE_NAME = supacode_cli`.
- Favor structured dispatch responses over string parsing.
- Keep command names/options mirrored with app deeplink/socket handlers.

## ANTI-PATTERNS
- Do not assume the app is running; preserve graceful deeplink/socket fallback behavior.
- Do not read app settings directly unless helper already owns that contract.
