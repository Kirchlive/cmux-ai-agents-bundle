---
name: cmux
description: Drive the cmux native macOS terminal app from CLI or socket — workspaces, panes, surfaces, sending input to and reading output from other surfaces, driving a second AI agent session, browser automation, notifications, sidebar metadata, session restore. Use whenever the user mentions cmux, wants to control terminal layout from an agent, start or steer another agent session in a split, read what another surface printed, automate browser panels on macOS, send notifications/flashes to the sidebar, or integrate an AI agent with cmux hooks. macOS only (14.0+).
---

# cmux Control

cmux is a native macOS terminal app for running multiple AI coding agents in parallel. It exposes a CLI (`cmux`) and a Unix-socket JSON-RPC API for full topology and browser control.

**Verb names below can drift between builds. `cmux --help` is the authority** — grep it before using a verb you have not run in this build, and on any `Unknown command` error grep it rather than guessing a variant.

The socket path is `$CMUX_SOCKET_PATH` (e.g. `~/.local/state/cmux/cmux-<uid>.sock`), not a fixed `/tmp/cmux.sock`. Always read it from the environment.

## Core Concepts

- **Window** — top-level macOS cmux window
- **Workspace** — sidebar tab within a window (one git branch / project context)
- **Pane** — split region inside a workspace
- **Surface** — tab inside a pane (terminal or browser)

Handles default to short refs (`workspace:2`, `pane:1`, `surface:7`); UUIDs accepted as input. Add `--id-format uuids|both` for full IDs in output.

## Detect cmux in a Shell

```bash
[ -S "${CMUX_SOCKET_PATH:-/tmp/cmux.sock}" ] || exit 0   # bail if not in cmux
[ -n "${CMUX_WORKSPACE_ID:-}" ] && echo "inside cmux surface"
```

Injected env vars in every cmux-spawned terminal: `CMUX_WORKSPACE_ID`, `CMUX_SURFACE_ID`, `CMUX_SOCKET_PATH`, `CMUX_PORT`. **Always anchor automation to `CMUX_WORKSPACE_ID`** — the visually focused workspace may not be the agent's caller workspace.

## Fast Start — Topology

```bash
cmux identify --json                              # who am I (window/workspace/pane/surface)
cmux tree                                         # full hierarchy
cmux list-workspaces --json
cmux list-panes --workspace "$CMUX_WORKSPACE_ID"
cmux list-pane-surfaces --pane pane:2                 # surfaces of one pane
cmux surface-health --surface surface:2               # is it alive / in-window

cmux new-workspace --name "feature-x" --cwd /path/to/repo
cmux new-pane --workspace "$CMUX_WORKSPACE_ID" --type terminal --direction right --focus false
cmux new-pane --workspace "$CMUX_WORKSPACE_ID" --type browser  --direction right --url http://localhost:3000
cmux move-surface --surface surface:7 --pane pane:2 --focus false
cmux split-off --surface surface:7 right
cmux reorder-surface --surface surface:7 --before surface:3
cmux close-surface --surface surface:7
```

## Send Input & Read Output

```bash
cmux send "echo hi"                                    # focused terminal
cmux send --surface surface:7 "npm run build"          # specific surface
cmux send-key --surface surface:7 enter                # enter|tab|esc|backspace|arrows|ctrl+x|shift+tab
cmux send-panel --panel panel:1 "text"                 # panel variant

cmux read-screen --surface surface:7 --lines 45        # snapshot of what is on screen
cmux read-screen --surface surface:7 --scrollback      # include scrollback
cmux capture-pane --surface surface:7 --lines 200      # same, pane-oriented
```

`read-screen` is the only way to see output. There is no streaming/tail verb — poll it after an action instead of building a watcher. Send text and the newline **separately** (`send`, then `send-key … enter`); embedding `\n` is unreliable in TUIs.

## Driving a Second Agent Session

Reuse an existing non-caller pane; only create one if none exists. Anchor to
`cmux identify --json` (`caller.pane_ref`) so the agent never drives its own surface.

```bash
cmux identify --json                                   # caller.pane_ref = own pane — avoid it
S=surface:2                                            # a pane you do NOT occupy
cmux send --surface $S 'claude --dangerously-skip-permissions'
cmux send-key --surface $S enter
sleep 14                                               # TUI boot; input before this hits the shell
cmux send --surface $S 'your prompt'
sleep 1                                                # let the slash/autocomplete popup settle
cmux send-key --surface $S enter
cmux read-screen --surface $S --lines 40               # poll for the result
```

- **`sleep 1` between text and Enter.** Without it a slash-command popup swallows the Enter.
- **`send-key … ctrl+u`** clears a half-typed line before sending something new.
- **`/exit`** ends an agent session cleanly; the surface is then reusable for a fresh start.
- **Menus** (e.g. `/mcp`) are navigable blind: send `down` N times, `read-screen` to confirm the
  cursor row, only then `enter`.
- **Do not identify the child by process name.** cmux launches agents as
  `claude --session-id <uuid> --settings {…}`, so `pgrep -f "claude --dangerously"` finds
  nothing, and a permanent cmux helper process looks like a user session. Use
  `cmux top --processes` instead.

## Notifications & Sidebar Metadata

```bash
cmux notify --title "Done" --body "tests passed"
cmux set-status build "compiling" --icon hammer --color "#ff9500"
cmux set-progress 0.5 --label "Building..."
cmux log --level success "All 42 tests passed"               # info|progress|success|warning|error
cmux trigger-flash --workspace "$CMUX_WORKSPACE_ID"          # blue-ring attention cue
cmux sidebar-state --json                                    # dump all sidebar metadata
```

## Browser Automation (WKWebView)

Workflow: open → wait → snapshot → act → re-snapshot.

```bash
S=$(cmux --json browser open https://example.com | jq -r .result.surface_ref)
cmux browser "$S" wait --load-state complete --timeout-ms 15000
cmux browser "$S" snapshot --interactive                     # returns elements as e1, e2, ...
cmux browser "$S" fill e1 "jane@example.com"
cmux browser "$S" click e2 --snapshot-after

# Navigation / inspection
cmux browser "$S" goto URL | back | forward | reload
cmux browser "$S" get url | get title | get text body | get value "#email" | get count ".row"
cmux browser "$S" eval 'return document.title'

# Waits
cmux browser "$S" wait --selector "#ready" --timeout-ms 10000
cmux browser "$S" wait --url-contains "/dashboard" --timeout-ms 10000

# Session
cmux browser "$S" cookies get | cookies set --name foo --value bar
cmux browser "$S" state save /tmp/auth.json | state load /tmp/auth.json

# Diagnostics
cmux browser "$S" console list | errors list | screenshot
```

**Not supported by WKWebView** (return `not_supported`): viewport emulation, geolocation/offline emulation, trace recording, network route interception, raw input injection.

## Markdown Viewer

```bash
cmux markdown open plan.md --direction right                 # live-watching renderer
cmux open file.pdf                                           # auto-routes to right viewer
```

## Settings & Config

```bash
cmux docs settings        # prints paths, schema URL, reload cmd — read BEFORE editing
cmux settings path        # path to cmux.json
cmux settings cmux-json   # open in editor
cmux reload-config        # hot-reload cmux.json + ~/.config/ghostty/config (Cmd+Shift+,)
```

Locations:
- cmux settings: `~/.config/cmux/cmux.json` (canonical). Project-local override: `.cmux/cmux.json` or `./cmux.json`.
- Terminal rendering (font, cursor, theme, scrollback, opacity, blur): `~/.config/ghostty/config` — NOT cmux.json.

Before editing `cmux.json`, copy it to a timestamped `.bak` next to it so the user can revert. Schema: `https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json`.

## Agent Hooks & Install

```bash
brew tap manaflow-ai/cmux && brew install --cask cmux
sudo ln -sf /Applications/cmux.app/Contents/Resources/bin/cmux /usr/local/bin/cmux
cmux hooks setup                                             # all detected agents
cmux hooks setup codex|grok|antigravity|opencode             # specific agent
npx skills add manaflow-ai/cmux -g -y                        # install cmux skills for agents
```

Native session-resume supported for: Claude Code, Codex, Grok, OpenCode, Pi, Amp, Cursor CLI, Gemini, Antigravity, Rovo Dev, Hermes, Copilot, CodeBuddy, Factory, Qoder.

## Socket API (advanced)

`$CMUX_SOCKET_PATH` — Unix socket, JSON-RPC v2. Use for tight loops where subprocess spawn cost matters; otherwise prefer the CLI.

```bash
echo '{"id":"1","method":"workspace.list","params":{}}' | nc -U "$CMUX_SOCKET_PATH"
```

Method prefixes: `system.*`, `window.*`, `workspace.*`, `pane.*`, `surface.*`, `notification.*`, `browser.*`. Full list and Python client example in `references/socket-api.md`.

Access modes: `cmuxOnly` (default — only cmux-spawned processes), `automation` (any local process), `password`, `allowAll` (unsafe). If you hit `Failed to connect to socket`, you're likely an external process under `cmuxOnly` — switch mode in Settings > Automation or run from inside a cmux terminal.

## Critical Rules — Non-Disruptive Automation

These rules come from the `cmux-workspace` skill and prevent agents from yanking the user's focus:

1. **Anchor to `CMUX_WORKSPACE_ID`.** Never assume the visually focused workspace is the target.
2. **Never call focus-changing verbs speculatively.** `select-workspace`, `focus-pane`, `focus-panel`, `focus-surface` only on explicit user request. Pass `--focus false` whenever available.
3. **Build layout additively in one call.** `cmux new-pane --type … --focus false` beats create-then-move-then-focus chains.
4. **Right-side helper pane pattern.** Reuse an existing non-caller helper pane if present; otherwise create exactly one right-side pane.
5. **Never send input to surfaces you don't own.** Only target surfaces in the caller's workspace unless the user explicitly asks for cross-workspace routing.
6. **Check surface health before routing input** when UI state may be stale: `cmux surface-health`.

## Common Pitfalls

- **`Unknown command` → grep `cmux --help`, do not guess a variant.** Verb names differ between builds; this document can lag behind the installed one.
- **Recipes use the socket API, not these CLI verbs.** Do not expect `cmux-recipes/` to demonstrate `send`, `send-key` or `read-screen`.
- **Pi/Pi-like socket connection failures from external processes** → default `cmuxOnly` mode; either run inside a cmux terminal or change socket mode.
- **macOS only.** No Linux/Windows port.
- **WKWebView ≠ CDP.** Don't expect Playwright-equivalent network mocking or viewport emulation.
- **Resume strips sensitive env vars.** Re-inject tokens at resume time if the agent needs them.
- **Skills snapshot at app start.** Edits to skill files require a restart of the consuming agent.
- **Legacy v1 socket payloads (`{"command":...}`) rejected.** Use v2 JSON-RPC only.
- **Don't `cat ~/.cmuxterm/*-hook-sessions.json`** expecting secrets — they're scrubbed. Look there for session/surface mappings only.

## Reference: Full CLI Help

For any command, `cmux <cmd> --help` is authoritative. Use `cmux capabilities --json` to enumerate available socket methods in the current build.

## Keyboard Shortcuts (most-used)

Workspaces: ⌘N new, ⌘1–8 jump, ⌃⌘[ / ⌃⌘] prev/next, ⌘⇧W close, ⌘B sidebar.
Surfaces: ⌘T new, ⌘⇧[ / ⌘⇧] prev/next, ⌘W close, ⌃1–8 jump.
Splits: ⌘D right, ⌘⇧D down, ⌥⌘D browser right, ⌥⌘←→↑↓ focus directional, ⌘⇧↵ zoom.
Browser: ⌘⇧L open, ⌘L address bar, ⌘[/⌘] back/forward, ⌥⌘I devtools.
App: ⌘, settings, ⌘⇧, reload-config, ⌘⇧P palette, ⌘⇧O restore session, ⌃⌥⌘. system-wide show/hide.
