# Changelog

## 1.0.4 — 2026-09-04

**Skill `cmux`** — rewritten and verified against cmux 0.64.22.

- New: *Wait for it to finish — do not poll the screen for stillness.* The
  signal is cmux's own per-session lifecycle record (`running / idle /
  needsInput`), which every hooked agent feeds through the same three
  transitions — read with `cmux sessions --agent <name> --json` (works on
  0.64.22 although `--help` does not list it) or from
  `~/.cmuxterm/<agent>-hook-sessions.json`, no socket required. Measured: a
  5×8 s screen-hash loop waited two to three minutes for a turn that ended
  seconds earlier, because the footer's per-minute counters keep resetting it.
- New: `scripts/wait-idle.sh` — agent-agnostic (Claude Code, Codex, Kimi Code,
  Gemini, OpenCode, Antigravity, Grok, Pi, Amp, Cursor, Copilot, …), selects
  by session-id prefix, cwd or pid, `--fresh` guards against stale idle, exit
  codes for idle / needs input / timeout / no record. Verified on 0.64.22
  against a running Claude Code session, an idle Codex session, and an
  unhooked agent.
- New: `references/waiting-for-an-agent.md`, `references/browser.md`,
  `references/socket-api.md` (the last was referenced by 1.0.3 but missing).
- Fixed: `cmux <verb> --help` does not exist on 0.64.x — only `cmux --help`
  and `cmux docs <topic>`; the skill no longer sends agents there.
- Fixed: "there is no streaming/tail verb" — `events`, `pipe-pane` and
  `wait-for` exist.
- Fixed: socket access mode (`socketControlMode`) is read at app start;
  changing it does not affect the running app.
- New: inline wait for short tasks — subscribe to `agent.hook.Stop` /
  `agent.hook.Notification` with `cmux events` before sending, block on the
  event, react in under a second, no script. Same names for every hooked
  agent; no replay without `--after`, so stale events cannot fool it.
- Added the rule *a completion notification is a queued task*: the wait runs
  in the background and its `WAIT-IDLE: DONE … NEXT: …` line almost always
  lands mid-task; the skill now says to queue the review as the next step,
  finish the current step, review, and only then send anything — with
  `NEEDS INPUT` (exit 3) jumping the queue. Observed failure it fixes: the
  supervising session read the notification, finished its own step, and never
  returned to the finished peer.
- Added the rule *idle first, then send*, and the note that waits over two
  minutes need the Bash tool's timeout raised or should run in the background.
- Browser automation moved out of `SKILL.md` into a reference; `SKILL.md` is
  shorter than before despite the additions.

**Recipes** — `12`, `13`, `14`, `20` no longer fall back to `/tmp/cmux.sock`;
the default is `~/.local/state/cmux/cmux-<uid>.sock`, matching the CLI.

**Docs** — README and skill README now say to copy the whole skill folder
(`SKILL.md` alone loses `references/` and `scripts/`), point at this fork, and
mention the plugin install path.

## 1.0.3

- Fix incorrect CLI verbs and document reading terminal output.
