---
name: cmux
description: Drive the cmux native macOS terminal app from the CLI or its socket — inspect and build the window/workspace/pane/surface layout, send input to and read output from other surfaces, start and steer a second AI agent session in a split and wait for it to finish without burning minutes on screen polling, automate browser panels, post notifications and sidebar status, read the agent event log. Use this whenever the user mentions cmux, wants an agent to control terminal layout, asks to run, prompt, mentor, supervise or observe another Claude Code / Codex / agent session from this one, wants to know when another session is done or idle, or needs macOS browser automation from a terminal — even if they do not say "cmux" but the shell has CMUX_* variables set. macOS only (14.0+).
---

# cmux Control

cmux is a native macOS terminal for running several AI coding agents side by
side. Everything the UI can do is reachable through the `cmux` CLI, which is a
thin client over a Unix-socket JSON-RPC API.

## Find the truth in the installed build first

Verb names, options and even which verbs exist change between builds, and this
document lags behind the binary. Three rules:

- `cmux --help` is the only authority. It prints the whole verb table; grep it
  before using a verb you have not run in this build.
- **There is no per-verb help.** `cmux <verb> --help` returns `Unknown command`
  on 0.64.x. Topic docs exist instead: `cmux docs settings|shortcuts|api|browser|agents|dock`.
- On `Unknown command`, grep `cmux --help` — do not guess a variant. Some
  verbs are aliases of newer forms (`list-workspaces` → `workspace list`) and
  print a deprecation notice; set `CMUX_QUIET=1` to silence it in scripts.

If `cmux` is not on `PATH`, it lives at
`/Applications/cmux.app/Contents/Resources/bin/cmux`. `cmux capabilities --json`
enumerates the socket methods of the running build.

## Concepts and handles

- **Window** — top-level macOS window
- **Workspace** — sidebar tab inside a window (one project or branch)
- **Pane** — split region inside a workspace
- **Surface** — tab inside a pane: terminal, browser, simulator or agent-session

Handles are short refs (`workspace:2`, `pane:1`, `surface:7`); UUIDs and
indices are accepted as input. Add `--id-format uuids|both` for full IDs in
output.

## Detect cmux from a shell

Every cmux-spawned terminal carries `CMUX_WORKSPACE_ID`, `CMUX_SURFACE_ID`,
`CMUX_SOCKET_PATH` and `CMUX_PORT`.

```bash
[ -S "${CMUX_SOCKET_PATH:-}" ] || exit 0        # not inside cmux
cmux identify --json                             # window / workspace / pane / surface of the caller
```

Anchor every automation to `CMUX_WORKSPACE_ID` and to `caller.pane_ref` from
`identify` — the visually focused workspace is not necessarily yours, and the
one surface you must never drive is your own.

The socket path is whatever `CMUX_SOCKET_PATH` says (usually
`~/.local/state/cmux/cmux-<uid>.sock`), never a fixed `/tmp/cmux.sock`.

## Topology

```bash
cmux tree                                              # full hierarchy
cmux list-workspaces --json
cmux list-panes --workspace "$CMUX_WORKSPACE_ID"
cmux list-pane-surfaces --pane pane:2
cmux surface-health --surface surface:2                # alive / in-window?

cmux new-workspace --name "feature-x" --cwd /path/to/repo --focus false
cmux new-pane --workspace "$CMUX_WORKSPACE_ID" --type terminal --direction right --focus false
cmux new-surface --pane pane:2 --type agent-session --provider claude --focus false   # or codex | opencode
cmux move-surface --surface surface:7 --pane pane:2 --focus false
cmux split-off --surface surface:7 right
cmux close-surface --surface surface:7
```

Build layout additively and in one call where you can (`new-pane … --focus
false`) instead of create → move → focus chains.

## Send input, read output

```bash
cmux send --surface surface:7 "npm run build"           # text only
cmux send-key --surface surface:7 enter                 # enter|tab|esc|backspace|up|down|left|right|ctrl+x|shift+tab
cmux send-key --surface surface:7 ctrl+u                # clear a half-typed line first

cmux read-screen --surface surface:7 --lines 45         # what is on screen now
cmux read-screen --surface surface:7 --scrollback       # include scrollback
cmux capture-pane --surface surface:7 --lines 200       # tmux-style alias
```

Send text and the newline **separately**; an embedded `\n` is unreliable in
TUIs. In a Claude Code prompt, `sleep 1` between `send` and `enter`, or the
slash-command popup swallows the Enter.

`read-screen` is a snapshot, not a stream. For a stream, `cmux events` tails
the app's event log and `pipe-pane --command` forwards a surface's output to a
command — both exist on 0.64.x; use them before building a polling watcher.

## Driving a second agent session

Reuse an existing non-caller pane; create one only if none exists. Then:

```bash
S=surface:7                                            # a surface you do NOT occupy
cmux send --surface $S 'claude'
cmux send-key --surface $S enter
sleep 14                                               # TUI boot; earlier input hits the shell
cmux send --surface $S 'your prompt'
sleep 1
cmux send-key --surface $S enter
```

- `/exit` ends the session cleanly; the surface is reusable afterwards.
- Menus (`/mcp`, `/model`) are navigable blind: send `down` N times,
  `read-screen` to confirm the cursor row, then `enter`.
- Do not identify the child by process name: cmux launches agents as
  `claude --session-id <uuid> --settings {…}`, so `pgrep -f "claude
  --dangerously"` finds nothing. Use `cmux top --processes`, or read the session
  id off the footer of the surface.

### Wait for it to finish — do not poll the screen for stillness

This is where most of the wasted time in agent-driving-agent setups goes.
A "screen stopped changing" loop needs a change-free window that the
footer's per-minute counters keep breaking; measured, it waits minutes for a
turn that ended seconds ago and sometimes reports "still working" by mistake.
It also cannot tell "done" from "waiting on a permission prompt".

cmux already knows. Its agent hooks keep one lifecycle record per session —
`running`, `idle`, `needsInput`, `unknown` — for **every agent it has hooks
for**, and every one of those agents maps its own events onto the same three
transitions (prompt submitted → running, stop → idle, notification →
needsInput). That record is the signal, and it is the same for Claude Code,
Codex, Kimi Code, Gemini, OpenCode, Antigravity, Grok, Pi, Amp, Cursor,
Copilot and the rest:

```bash
cmux sessions --agent codex --json          # all agents when --agent is omitted; no socket needed
# → sessions[].agent_lifecycle, session_id, cwd, pid, surface_id, updated_at_unix
```

`cmux sessions` is not listed by `cmux --help` on 0.64.22 but exists; the
same data is in `~/.cmuxterm/<agent>-hook-sessions.json` (`agentLifecycle`)
for builds that lack the verb. The bundled script wraps both, with a
screen-hash fallback for sessions that have no record:

```bash
scripts/wait-idle.sh --agent claude --session <id-prefix> --fresh --timeout 600
scripts/wait-idle.sh --agent codex  --cwd /path/to/repo
# exit 0 idle · 3 needs input · 2 timeout · 4 no record and no --surface
```

`--fresh` after sending a prompt: it refuses an idle state recorded before
the script started, so the peer's previous idle does not count as done.
Read the surface only after exit 0.

One precondition: the agent must have cmux hooks installed. Claude Code gets
them through the cmux wrapper; every other agent needs `cmux hooks setup
<agent>` once (`cmux hooks setup` does all that are on `PATH`). No record →
no signal → the script falls back to the screen hash, which needs `--surface`
and the socket. Claude Code additionally offers its own session record and
`notify_when_idle`; both are extras, not the primary signal — see
[references/waiting-for-an-agent.md](references/waiting-for-an-agent.md).

**Short tasks: send and wait in one call, no script.** For a prompt you
expect back within a minute or two, subscribe to the hook event *before*
sending and block on it — the event stream reacts in well under a second
and needs no polling. Works from inside cmux (socket) for every hooked
agent:

```bash
S=surface:7; SID=507e4562; F=$(mktemp)                        # peer surface, its session-id prefix
cmux events --name agent.hook.Stop --name agent.hook.Notification --no-ack --no-heartbeat --timeout 100 >"$F" 2>/dev/null & EV=$!
cmux send --surface $S 'rename the helper and run the tests'; sleep 1; cmux send-key --surface $S enter
until grep -q "$SID" "$F"; do kill -0 $EV 2>/dev/null || break; sleep 0.2; done; kill $EV 2>/dev/null
grep -q "agent.hook.Notification.*$SID" "$F" && echo NEEDS-INPUT; grep -q "agent.hook.Stop.*$SID" "$F" && echo DONE || echo TIMEOUT
rm -f "$F"; cmux read-screen --surface $S --lines 40
```

Subscribe first, send second: the stream carries no history (without
`--after` it starts at the latest sequence), so a Stop that fires before the
subscription exists is never seen. Keep `--timeout` under the Bash tool's
limit; when it expires, fall back to the script below in the background.
For anything longer than a couple of minutes, or when you want to keep
working meanwhile, use the script.

Run the long wait in the background. Its completion line is written as an
instruction (`WAIT-IDLE: DONE … NEXT: …`), and it will usually arrive
**while you are doing something else**. That is the case where reviews get
lost, so treat it as a rule, not a hint:

- **A completion notification is a queued task, not information.** The
  moment it arrives, add "review <session>" to your task list as the next
  item after the step you are on. Do not acknowledge it in prose and move on.
- **Finish the current step, then review — before any new prompt to
  anyone.** Read the peer's surface, check what it produced (commits, tests,
  files), decide accept / correct / continue, and only then send the next
  instruction.
- **Exit 3 (`NEEDS INPUT`) jumps the queue.** The peer is blocked on a
  permission prompt or a question; nothing it does progresses until you
  answer. Interrupt your own step for that.
- **If a wait returned and you cannot find its notification, check the
  lifecycle yourself** (`cmux sessions --agent … --json`) before assuming
  the peer is still working — a background task whose output you never read
  looks exactly like one that never finished.

Two consequences for the sending side:

- **Idle first, then send.** A prompt delivered mid-turn queues behind the
  running work and can leave it half-finished, or answer a question the agent
  was about to ask. Check, send, `sleep 1`, enter.
- **A wait longer than two minutes needs the Bash tool's timeout raised** or it
  is killed silently; better, run it in the background so the completion
  notification wakes you and the polling output stays out of your context.

## Notifications and sidebar metadata

```bash
cmux notify --title "Done" --body "tests passed"
cmux set-status build "compiling" --icon hammer --color "#ff9500"
cmux set-progress 0.5 --label "Building..."
cmux log --level success "All 42 tests passed"          # info|progress|success|warning|error
cmux trigger-flash --workspace "$CMUX_WORKSPACE_ID"     # blue-ring attention cue
cmux list-status --workspace "$CMUX_WORKSPACE_ID"       # includes the agents' claude_code state
cmux sidebar-state --json
```

## Browser, markdown, files

Browser surfaces are WKWebViews driven with `cmux browser <surface> …`
(open → wait → snapshot → act → re-snapshot). The verbs, their limits and the
things WKWebView cannot do are in [references/browser.md](references/browser.md).

```bash
cmux markdown open plan.md --direction right            # live-reloading viewer
cmux open file.pdf                                      # routes to the right viewer
cmux diff --unstaged --workspace "$CMUX_WORKSPACE_ID"   # diff viewer surface
```

## Settings

```bash
cmux docs settings        # paths, schema URL, reload command — read before editing
cmux settings path        # ~/.config/cmux/cmux.json
cmux config doctor
cmux reload-config        # hot-reloads cmux.json and ~/.config/ghostty/config, no restart
```

cmux-owned behaviour lives in `~/.config/cmux/cmux.json`; terminal rendering
(font, theme, opacity, blur, scrollback) lives in `~/.config/ghostty/config`.
Back up `cmux.json` to a timestamped `.bak` next to it before editing.

## Socket access from outside cmux

The socket admits only processes started inside cmux by default
(`cmuxOnly`); an external process gets `Access denied`. The mode is read at
app start, so flipping it in preferences does not affect the running app, and
restarting cmux ends every hosted session. When something outside cmux has to
observe or wait for an agent, use the file-based signals above rather than
changing the mode mid-flight. Modes and the raw JSON-RPC calls are in
[references/socket-api.md](references/socket-api.md).

## Hooks and install

```bash
brew tap manaflow-ai/cmux && brew install --cask cmux
sudo ln -sf /Applications/cmux.app/Contents/Resources/bin/cmux /usr/local/bin/cmux
cmux hooks setup                      # every hooked agent found on PATH
cmux hooks setup kimi                 # one agent: codex grok opencode pi omp campfire amp cursor
                                      # gemini kimi kiro rovodev copilot codebuddy factory qoder
                                      # (Claude Code needs none — the cmux wrapper injects them)
cmux sessions --json                  # what the hooks recorded, per agent, without the socket
```

The hooks give three things at once: the lifecycle record above, session
restore after a relaunch (`cmux sessions` shows what is restorable), and the
Feed approval cards. Resume strips sensitive env vars; re-inject tokens if the
agent needs them. Kimi Code is hooked for lifecycle and Feed but not yet for
restore.

## Non-disruptive automation

1. Anchor to `CMUX_WORKSPACE_ID` and the caller's pane; never drive your own
   surface.
2. Never call focus-changing verbs speculatively (`select-workspace`,
   `focus-pane`, `focus-panel`, `focus-surface`) — only on explicit request.
   Pass `--focus false` wherever it exists.
3. Never send input to a surface you do not own unless the user asked for that
   routing; check `surface-health` first when the UI state may be stale.
4. Reuse an existing helper pane; otherwise create exactly one, to the right.
5. Idle before send, for any surface that runs an agent.

## Pitfalls

- `cmux <verb> --help` does not exist; `cmux --help` does. Grep it.
- Recipes in `cmux-recipes/` use the socket API, not `send`/`read-screen`.
- Skills are snapshotted when the consuming agent starts; edits to a skill
  file need that agent restarted.
- Legacy v1 socket payloads (`{"command":…}`) are rejected; v2 JSON-RPC only.
- `~/.cmuxterm/<agent>-hook-sessions.json` is scrubbed of secrets and prompts,
  but it is not empty: it carries `agentLifecycle`, `cwd`, `pid`, surface and
  workspace ids per session — `cmux sessions --json` reads the same files.
- A hooked agent whose store file never appears has no hooks: run
  `cmux hooks setup <agent>` (Kimi Code writes into `~/.kimi-code/config.toml`).
- WKWebView ≠ Chromium: no network interception, no viewport emulation.
- macOS only.

## Keyboard shortcuts (most used)

Workspaces: ⌘N new, ⌘1–8 jump, ⌃⌘[ / ⌃⌘] prev/next, ⌘⇧W close, ⌘B sidebar.
Surfaces: ⌘T new, ⌘⇧[ / ⌘⇧] prev/next, ⌘W close, ⌃1–8 jump.
Splits: ⌘D right, ⌘⇧D down, ⌥⌘D browser right, ⌥⌘←→↑↓ focus, ⌘⇧↵ zoom.
App: ⌘, settings, ⌘⇧, reload-config, ⌘⇧P palette, ⌘⇧O restore session.

## References

| File | Read when |
| :-- | :-- |
| `references/waiting-for-an-agent.md` | you need to know when another agent session is done, or before writing any wait loop |
| `references/browser.md` | automating a browser surface |
| `references/socket-api.md` | calling the socket directly, access modes, the event stream |
| `scripts/wait-idle.sh` | run it; do not reimplement it — it works for every hooked agent, not only Claude Code |
