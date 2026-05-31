# Awesome cmux

> A curated list of everything around [cmux](https://cmux.com) — the native macOS terminal built for running multiple AI coding agents in parallel.

Contributions welcome — open a PR or an issue.

---

## Contents

- [Official](#official)
- [Install](#install)
- [Skills (Official)](#skills-official)
- [Supported AI agents](#supported-ai-agents)
- [Hooks & integrations](#hooks--integrations)
- [Browser automation](#browser-automation)
- [Configuration](#configuration)
- [Articles & write-ups](#articles--write-ups)
- [Videos & demos](#videos--demos)
- [Community](#community)
- [Companion tools](#companion-tools)
- [In this bundle](#in-this-bundle)

---

## Official

- [cmux.com](https://cmux.com) — homepage
- [cmux.com/docs](https://cmux.com/docs) — getting started
- [cmux.com/docs/configuration](https://cmux.com/docs/configuration) — full `cmux.json` schema reference
- [cmux.com/docs/api](https://cmux.com/docs/api) — CLI and socket API reference
- [cmux.com/docs/notifications](https://cmux.com/docs/notifications) — notification system, OSC sequences, hooks
- [cmux.com/docs/ssh](https://cmux.com/docs/ssh) — SSH workspaces and browser routing
- [cmux.com/docs/session-restore](https://cmux.com/docs/session-restore) — session restore, supported agents, resume commands
- [cmux.com/docs/skills](https://cmux.com/docs/skills) — skills system
- [cmux.com/docs/custom-commands](https://cmux.com/docs/custom-commands) — actions, layouts, surface definitions
- [GitHub: manaflow-ai/cmux](https://github.com/manaflow-ai/cmux) — source repo
- [GitHub: CHANGELOG.md](https://raw.githubusercontent.com/manaflow-ai/cmux/main/CHANGELOG.md) — full version history
- [DeepWiki: manaflow-ai/cmux](https://deepwiki.com/manaflow-ai/cmux) — auto-generated architecture overview
- [Mintlify socket-api reference](https://manaflow-ai-cmux.mintlify.app/automation/socket-api) — full JSON-RPC method list

## Install

- DMG: [latest release](https://github.com/manaflow-ai/cmux/releases/latest/download/cmux-macos.dmg)
- Homebrew: `brew tap manaflow-ai/cmux && brew install --cask cmux`
- Nightly builds: separate `cmux NIGHTLY` app, see GitHub releases
- CLI symlink: `sudo ln -sf "/Applications/cmux.app/Contents/Resources/bin/cmux" /usr/local/bin/cmux`

## Skills (Official)

Install all: `npx skills add manaflow-ai/cmux -g -y`

- [cmux Core](https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux/SKILL.md) — windows, workspaces, panes, surfaces, focus, moves
- [cmux Workspace](https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-workspace/SKILL.md) — caller-workspace-scoped automation, non-disruptive rules
- [cmux Settings](https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-settings/SKILL.md) — safe `cmux.json` edits
- [cmux Customization](https://github.com/manaflow-ai/cmux/tree/main/skills/cmux-customization) — actions, layouts, tab buttons
- [cmux Diagnostics](https://github.com/manaflow-ai/cmux/tree/main/skills/cmux-diagnostics) — CLI/socket/hooks health checks
- [cmux Browser](https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-browser/SKILL.md) — WKWebView browser automation
- [cmux Markdown Viewer](https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-markdown/SKILL.md) — live-watching markdown panel

## Supported AI agents

cmux ships first-class session-restore + hook integration for these:

| Agent | Resume command | Hook feed |
|---|---|---|
| [Claude Code](https://docs.anthropic.com/claude-code) | `claude --resume <id>` | `PermissionRequest` |
| [Codex](https://github.com/openai/codex) | `codex resume <id>` | `PreToolUse`, `PermissionRequest` |
| [Grok / Grok Build CLI](https://x.ai) | `grok -r <id>` | `PreToolUse` |
| [OpenCode](https://github.com/sst/opencode) | `opencode --session <id>` | plugin event bus |
| [Pi](https://pi.ai) | `pi --session <id>` | — |
| [Amp](https://ampcode.com) | `amp threads continue <id>` | — |
| [Cursor CLI](https://cursor.com) | `cursor-agent --resume <id>` | `beforeShellExecution` |
| [Gemini](https://gemini.google.com) | `gemini --resume <id>` | `PreToolUse` |
| [Antigravity CLI](https://antigravity.google) | `agy --conversation <id>` | `PreToolUse`, `PostToolUse` |
| [Rovo Dev](https://www.atlassian.com/software/rovo) | `acli rovodev run --restore <id>` | — |
| [Hermes Agent](https://hermes-agent.nousresearch.com) | `hermes --resume <id>` | pre/post tool, approval |
| [Copilot CLI](https://github.com/features/copilot) | `copilot --resume <id>` | `PreToolUse` |
| [CodeBuddy](https://copilot.tencent.com) | `codebuddy --resume <id>` | `PreToolUse` |
| [Factory (droid)](https://factory.ai) | `droid --resume <id>` | `PreToolUse` |
| [Qoder](https://qoder.com) | `qodercli --resume <id>` | `PreToolUse` |

Install all detected hooks at once: `cmux hooks setup`

## Hooks & integrations

- [Official OSC 9 / 99 / 777 notification protocol](https://cmux.com/docs/notifications)
- [cmux notify CLI](https://cmux.com/docs/api) — `cmux notify --title "..." --body "..."`
- [Claude Code hook example](https://cmux.com/docs/notifications#manual-claude-code-hook)
- [`cmux-skill/` in this repo](../cmux-skill) — drop-in skill that wires any agent into cmux

## Browser automation

cmux includes an embedded WKWebView browser with a scriptable API (ported from agent-browser).

- [Browser commands reference](https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-browser/references/commands.md)
- [Browser skill](https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-browser/SKILL.md)
- Known WKWebView limitations (return `not_supported`): viewport emulation, offline mode, trace recording, network interception, raw input injection

## Configuration

- [cmux.json schema](https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json)
- Config locations:
  - `~/.config/cmux/cmux.json` (canonical)
  - `~/.config/ghostty/config` (terminal rendering, font, theme)
  - `.cmux/cmux.json` (project-local override)
- Reload without restart: `cmux reload-config` or `⌘⇧,`

## Articles & write-ups

- [Teaching Coding Agents to Drive cmux](https://bounds.dev) — Jesse Bounds
- [cmux: the terminal built for AI coding agents](https://dev.to/neuraldownload/cmux-the-terminal-built-for-ai-coding-agents-3l7h) — DEV.to overview
- [cmux: native macOS terminal for parallel AI coding agents](https://dev.to/arshtechpro/cmux-the-native-macos-terminal-built-for-running-ai-coding-agents-in-parallel-52il) — DEV.to technical guide
- [HN: Teaching Coding Agents to Drive Cmux](https://news.ycombinator.com/item?id=47258502) — discussion thread

## Videos & demos

- [David Ondrej — cmux walkthrough](https://youtube.com/@davidondrej) — full setup + 5-agent workflow demo
- [Manaflow founders demo](https://x.com/lawrencecchen) — feature drops on X
- *Open a PR to add more*

## Community

- [GitHub Discussions](https://github.com/manaflow-ai/cmux/discussions)
- [GitHub Issues](https://github.com/manaflow-ai/cmux/issues) — bug reports, feature requests
- founders@manaflow.com — commercial license inquiries

## Companion tools

Useful next to cmux:

- [Ghostty](https://ghostty.org) — the rendering engine cmux is built on (use its config for fonts/theme)
- [Claude Code](https://docs.anthropic.com/claude-code) — Anthropic's terminal agent
- [Codex CLI](https://github.com/openai/codex) — OpenAI's terminal agent
- [Hermes Agent](https://hermes-agent.nousresearch.com) — open-source agent runtime with cmux integration
- [npx skills](https://www.npmjs.com/package/skills) — Vercel's skills installer (cmux ships skills via this)
- [tmux](https://github.com/tmux/tmux) — the OG terminal multiplexer (cmux is the GUI-native take)

## In this bundle

- [`../cmux-skill/`](../cmux-skill) — drop-in skill that teaches any agent to drive cmux
- [`../cmux-recipes/`](../cmux-recipes) — 20 copy-paste socket-API + CLI snippets

---

Maintained at [davidondrej.com](https://davidondrej.com). PRs welcome.
