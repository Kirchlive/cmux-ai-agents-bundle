# cmux-skill

A single drop-in skill that teaches any AI coding agent how to drive **cmux** — the native macOS terminal for parallel AI agents — through its CLI and Unix-socket JSON-RPC API.

## Install

For agents that read `skills/` directories (Claude Code, Hermes, etc.), copy or symlink `SKILL.md` into your agent's skills folder:

Copy the **whole folder** — `SKILL.md` on its own loses `references/` and
`scripts/wait-idle.sh`, which the skill points at:

```bash
# Claude Code
cp -R skills/cmux-skill ~/.claude/skills/cmux

# Hermes
cp -R skills/cmux-skill ~/.hermes/skills/cmux
```

Or, project-local:

```bash
cp -R skills/cmux-skill .claude/skills/cmux
```

Or as a plugin (keeps it updatable):

```bash
claude plugin marketplace add Kirchlive/cmux-ai-agents-bundle
claude plugin install cmux-ai-agents-bundle@cmux-ai-agents-bundle
```

Or use the manaflow installer:

```bash
npx skills add manaflow-ai/cmux -g -y
```

## What's in it

- `SKILL.md` — topology primitives and short-ref handles, environment detection,
  send/read, driving a second agent session, notifications and sidebar
  metadata, settings, the non-disruptive automation rules, and the corrections
  measured against cmux 0.64.22 (no per-verb `--help`; `events` and
  `pipe-pane` exist; the socket path is never `/tmp/cmux.sock`).
- `references/waiting-for-an-agent.md` — why a "screen stopped changing" loop
  is slow, and the signal that replaces it for **every hooked agent**: cmux's
  own lifecycle record (`running / idle / needsInput`), read with
  `cmux sessions --agent <name> --json` or from
  `~/.cmuxterm/<agent>-hook-sessions.json`, no socket needed. Claude Code's
  own session record and `notify_when_idle` are documented as extras.
- `scripts/wait-idle.sh` — blocks until a driven agent session has finished
  its turn: Claude Code, Codex, Kimi Code, Gemini, OpenCode, Antigravity,
  Grok, Pi, Amp, Cursor, Copilot and every other agent `cmux hooks setup`
  covers. Select by `--agent` plus session-id prefix, cwd or pid; `--fresh`
  ignores an idle state older than the prompt you just sent. Exit `0` idle,
  `3` waiting on input, `2` timeout, `4` no record. Its completion line is
  written as an instruction (`WAIT-IDLE: DONE … NEXT: …`) so that, run in the
  background, the notification itself tells the supervising agent to queue
  the review rather than let it drop.
- `references/browser.md` — WKWebView automation (open → wait → snapshot → act)
  and what WKWebView cannot do.
- `references/socket-api.md` — JSON-RPC v2 calls, access modes, and the event
  stream.

## When the agent should load it

- The user mentions cmux.
- The agent is asked to run, prompt, mentor, supervise or observe another agent
  session, or wants to know whether another session is done or idle.
- The agent is being asked to control terminal layout from inside an automation loop.
- The agent needs to drive a browser surface on macOS.
- The agent wants to send notifications / flashes to the sidebar.
- The agent is being wired into cmux hooks.

## Requires

- cmux v0.64.0+ (`brew tap manaflow-ai/cmux && brew install --cask cmux`); verified against 0.64.22
- `cmux hooks setup <agent>` for every agent except Claude Code (hooked by the cmux wrapper); this is what feeds the lifecycle record the wait signal reads
- macOS 14.0+

## License

MIT. Same as the parent bundle.
