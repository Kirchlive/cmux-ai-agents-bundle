# Waiting for a driven agent session

Read this before building any loop that waits for another agent session to
finish. The obvious approach — poll `read-screen` until the screen stops
changing — is the slowest one available, and it is the one every agent
builds first.

## Why a screen-stability loop is slow

An agent's screen is never still. Claude Code's footer carries usage
counters that tick every minute (`5h: 17% 3h 49m · 7d: 15% 4h 56m`), the
working line carries a seconds clock and a token count, and a custom status
line may show a clock; other agents have their own spinners and clocks. A
loop that requires N identical snapshots at K-second spacing needs a
change-free window of N×K seconds; a minute tick falls inside a 40-second
window two times out of three and resets the count. Measured on a 5×8 s
loop: two to three minutes of waiting for a turn that ended seconds earlier,
and occasionally a false "still working" when the iteration cap ran out
first. Each round also pulls a screenful of text into the caller's context.

Use a positive signal instead.

## The primary signal — cmux's own lifecycle record (all agents)

cmux integrates with agents through hooks (`docs/agent-hooks.md` in the cmux
repository). Each integration maps the agent's native events onto the same
three cmux transitions, so the record it keeps has one shape for every
agent:

| cmux subcommand | fed by (examples) | lifecycle |
| :-- | :-- | :-- |
| `prompt-submit` | Claude/Codex/Kimi `UserPromptSubmit`, Antigravity `PreInvocation`, Hermes `on_tool_permission` | `running` |
| `stop` | `Stop` (Claude, Codex, Kimi, Grok…), Antigravity `turn-completion`, Hermes `on_complete` | `idle` |
| `notification` | `Notification` (permission prompts, questions) | `needsInput` |

The record lives in `~/.cmuxterm/<agent>-hook-sessions.json` under
`sessions[<id>].agentLifecycle` with `cwd`, `pid`, `surfaceId`, `workspaceId`
and `updatedAt`, and is exposed by the CLI **without the socket**:

```bash
cmux sessions --agent claude --json      # or codex, kimi, gemini, opencode, antigravity, grok,
cmux sessions --json --all               # pi, omp, campfire, amp, cursor, kiro, rovodev,
                                         # copilot, codebuddy, factory, qoder, hermes-agent
```

Output fields that matter: `agent`, `session_id`, `agent_lifecycle`, `cwd`,
`pid`, `surface_id`, `workspace_id`, `updated_at_unix`. On 0.64.22 the verb
works although `cmux --help` does not list it; on a build without it, read
the store file directly — same data, camelCase keys.

Two preconditions:

- **The agent must be hooked.** Claude Code is hooked automatically through
  the cmux wrapper. Every other agent needs `cmux hooks setup <agent>` once;
  `cmux hooks setup` does all that are on `PATH`. Kimi Code is included
  (`~/.kimi-code/config.toml`, or `~/.kimi/config.toml` for Kimi CLI ≤ 1.49).
  No store file for an agent means no hooks — not "the agent is idle".
- **Stale idle.** A session that was idle before you sent the prompt still
  reads `idle` until its `prompt-submit` hook fires. Compare `updated_at_unix`
  against the moment you sent, or use the script's `--fresh`.

`needsInput` is the state a stability loop cannot tell apart from idle: the
screen is still because the agent is waiting on a permission prompt or a
question. Treat it as a separate outcome, not as done.

## Inline wait for short tasks — the event stream

For a task you expect back within a minute or two, blocking on the event is
faster than polling and needs no script. `cmux events` streams the event
bus over the socket; `--name` filters server-side and repeats, `--timeout`
is seconds, and without `--after` the subscription starts at the latest
sequence — there is no replay, so stale events cannot fool it. Heartbeats
arrive every 15 s and are suppressed with `--no-heartbeat`.

Every hooked agent publishes its lifecycle through the same names
(`Sources/CmuxEventPublishing.swift`: `agent.hook.<HookEventName>` with the
agent as `source`), so `agent.hook.Stop` is the turn end for Claude Code,
Codex, Kimi and the rest alike, and `agent.hook.Notification` the blocked
state. The payload carries `session_id`, which is what you match on.

```bash
S=surface:7; SID=507e4562; F=$(mktemp)
cmux events --name agent.hook.Stop --name agent.hook.Notification --no-ack --no-heartbeat --timeout 100 >"$F" 2>/dev/null & EV=$!
cmux send --surface $S 'your short prompt'; sleep 1; cmux send-key --surface $S enter
until grep -q "$SID" "$F"; do kill -0 $EV 2>/dev/null || break; sleep 0.2; done; kill $EV 2>/dev/null
grep -q "agent.hook.Notification.*$SID" "$F" && echo NEEDS-INPUT
grep -q "agent.hook.Stop.*$SID" "$F" && echo DONE || echo TIMEOUT
rm -f "$F"; cmux read-screen --surface $S --lines 40
```

Why the temp file instead of a pipe: `cmux events | grep -m1` returns
immediately for grep, but the shell then waits for `cmux` to notice the
closed pipe, which only happens on its next write — up to one heartbeat
later. Writing to a file and killing the stream explicitly reacts within
the 0.2 s poll, in bash and zsh alike.

Order matters: subscribe, then send. A Stop that fires before the
subscription exists is never delivered. And keep the whole call under the
Bash tool's timeout; if the task turns out longer, let it expire and switch
to the script in the background — the lifecycle record will still show
`idle` when the peer finishes, nothing is lost.

Limits: needs the socket (inside cmux, or `automation` mode); and it sees
only sessions whose hooks publish to the bus — the same precondition as the
lifecycle record.

## The bundled script

`scripts/wait-idle.sh` polls `cmux sessions` (falling back to the store
file), selects the record by session-id prefix, cwd or pid, and honours
`--fresh`:

```bash
scripts/wait-idle.sh --agent claude --session 59fc8b47 --fresh --timeout 600
scripts/wait-idle.sh --agent codex  --cwd /path/to/repo
scripts/wait-idle.sh --agent kimi   --session 3f2a --surface surface:4   # hash fallback if unhooked
```

Exit codes: `0` idle, `3` waiting on input, `2` timeout, `4` no record and
no `--surface`. Verified on cmux 0.64.22 against a running Claude Code
session (timeout, correct), an idle Codex session (exit 0 within one poll),
the same Codex session with `--fresh` (timeout, correct — its idle was
stale), and an unhooked agent (exit 4).

## Claude Code extras

Claude Code has two more signals of its own. They are not better than the
cmux record — they are simply available when cmux hooks are not:

- `${CLAUDE_CONFIG_DIR:-~/.claude}/sessions/<pid>.json` carries
  `"status": "busy" | "idle"` at turn boundaries. Resolve it by `sessionId`,
  not by pid — the pid changes on resume.
- A Claude Code session driving another one can send its prompt through
  `SendMessage` with `notify_when_idle` and receive exactly one notice when
  the peer next goes idle — no polling, no blocking Bash call.

## Other things you may see and should not rely on

- `~/.cmuxterm/events.jsonl` — the event log behind `cmux events`. Claude
  Code's hook events appear there as `agent.hook.Stop` etc. with
  `_source: "claude"`; other agents' events may or may not, depending on how
  their integration reports. Use it for diagnostics, not as the wait signal.
- The sidebar status key (`claude_code`, `codex`, `kimi`, …) set to
  `Running`, `Idle` or `Needs input` — the same information, visible through
  `cmux list-status`, but that needs the socket.

## When the completion arrives while you are busy

The wait runs in the background, so its completion almost always lands in
the middle of your own step — a build, a review of something else, a
message you are composing. Observed failure: the supervising session reads
the notification, finishes its own step, and never returns to the peer,
which now sits idle with finished work nobody has looked at. The peer does
not re-notify; the signal fires once.

So the notification is a **task to queue**, not a status to note:

1. When `WAIT-IDLE: DONE` arrives, append "review <session> — <what it was
   asked>" to your task list immediately, positioned right after the step
   you are on. Writing it down is the whole point; a review you only
   intend to do is the one that gets lost.
2. Finish the current step. Do not start a new one.
3. Review the peer: read its surface (`NEXT:` in the notification carries
   the command), inspect the artefacts it claims (`git log`, tests, files),
   and decide accept / correct / continue.
4. Only then send the next prompt — to that peer or to anyone.

`WAIT-IDLE: NEEDS INPUT` (exit 3) is the exception that jumps the queue:
the peer is blocked and burns nothing but time until you answer. Interrupt
your own step.

If you suspect a wait completed and you missed it, do not wait again on a
session that may already be idle — check `cmux sessions --agent <name>
--json` first. A wait with `--fresh` on an already-idle session will sit
until its timeout, because no new idle transition is coming.

## Whichever method: mind the tool timeout

A wait that can exceed two minutes runs into the Bash tool's default
timeout and is killed without a result — the caller then sees nothing and
starts another loop. Either raise the timeout on that call, or run the wait
in the background (`ctrl+b`) and let the completion notification wake the
caller; that is also what keeps the caller's context small.

## Idle is the precondition for sending

A prompt delivered mid-turn queues behind the running work, and a prompt
that lands while the agent is composing a question can answer it
unintentionally. Check idle, then `send`, wait a second, then `send-key …
enter`. If text is already sitting in the peer's prompt line (a human typed
it and did not send), you are editing that human's input — do it only when
that is clearly intended, and say so.
