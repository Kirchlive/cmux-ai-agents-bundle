# cmux AI Agents Bundle — Marketplace

> 20 ready-to-run recipes + the full cmux control skill for Claude Code.  
> Install any single recipe or the whole bundle. MIT licensed.

```bash
npx skills add manaflow-ai/cmux -g -y   # skill via npx
# or copy any recipe.sh directly into your project
```

---

## ⚙️ Core

| Plugin | Type | Description |
|--------|------|-------------|
| [cmux Control Skill](./skills/cmux-skill/SKILL.md) | skill | Full cmux CLI + socket API — workspaces, panes, surfaces, browser, notifications, session restore |

---

## 🔔 Notifications

| Recipe | Description |
|--------|-------------|
| [01 — Notify on Build Fail](./cmux-recipes/01-notify-on-build-fail/) | Fire a system notification when your build command fails |
| [02 — Flash on Test Pass](./cmux-recipes/02-flash-on-test-pass/) | Blue-ring workspace flash when tests go green |
| [08 — Sidebar Progress Bar](./cmux-recipes/08-progress-bar-from-script/) | Pipe any 0–100 script output into the sidebar progress bar |
| [09 — Sticky Status Pill](./cmux-recipes/09-sidebar-status-pill/) | Persistent color-coded status label on the sidebar |

---

## 🌐 Browser

| Recipe | Description |
|--------|-------------|
| [03 — Screenshot Browser Surface](./cmux-recipes/03-screenshot-browser-surface/) | Snapshot a WKWebView surface to disk |
| [11 — Fill & Submit Form](./cmux-recipes/11-browser-fill-and-submit/) | Open URL → fill fields by ref → submit |
| [18 — Wait for Element](./cmux-recipes/18-browser-wait-for-element/) | Block until a CSS selector appears before acting |

---

## 🪟 UI & Layout

| Recipe | Description |
|--------|-------------|
| [04 — Spawn Helper Pane](./cmux-recipes/04-spawn-helper-pane/) | Right-side helper pane, no focus steal |
| [05 — Send Text to Surface](./cmux-recipes/05-send-text-to-other-surface/) | Route a command to any surface by ref |
| [10 — Open Markdown Viewer](./cmux-recipes/10-open-markdown-with-watch/) | Live-watching Markdown renderer in a new pane |
| [15 — Batch Rename Workspaces](./cmux-recipes/15-batch-rename-workspaces/) | Rename all workspaces to their cwd basename |

---

## 🤖 Agents

| Recipe | Description |
|--------|-------------|
| [07 — Three Agents on One PR](./cmux-recipes/07-three-agents-on-pr/) | Reviewer + implementer + tester panes on one branch |
| [19 — Agent Handoff Notification](./cmux-recipes/19-agent-handoff-notification/) | Notify + pass context when one agent hands off to the next |

---

## 🚀 DevOps

| Recipe | Description |
|--------|-------------|
| [06 — Tail Vercel Deploy](./cmux-recipes/06-tail-vercel-deploy/) | Live status pill while a Vercel deploy runs |
| [16 — Auto Flash on Stale PR](./cmux-recipes/16-auto-flash-on-stale-pr/) | Flash workspace when a PR has no activity for N days |
| [17 — SSH Remote Workspace](./cmux-recipes/17-ssh-remote-workspace/) | New workspace → SSH into remote VPS → launch agent |

---

## ⚡ Automation

| Recipe | Description |
|--------|-------------|
| [12 — Poll Socket for Events](./cmux-recipes/12-poll-socket-for-events/) | JSON-RPC event loop over /tmp/cmux.sock |
| [13 — Detect cmux Context](./cmux-recipes/13-detect-cmux-context/) | Guard any script with CMUX_WORKSPACE_ID + socket check |
| [14 — Python RPC Client](./cmux-recipes/14-python-rpc-client/) | Two-function stdlib-only Python snippet for cmux socket |
| [20 — Restore Session on Boot](./cmux-recipes/20-restore-session-on-boot/) | Re-build your full workspace layout after reboot |

---

Machine-readable catalog: [`.claude-plugin/marketplace.json`](./.claude-plugin/marketplace.json)
