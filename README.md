# cmux AI Agents Bundle

Free, MIT-licensed kit for developers who run multiple AI coding agents inside [cmux](https://cmux.com) — the native macOS terminal built for parallel AI workflows.

If you have ever opened five cmux workspaces, lost track of which agent owns which surface, and accidentally stolen focus from the user three times in one minute, this bundle is for you.

> Companion to David Ondrej's [cmux walkthrough on YouTube](https://youtube.com/@davidondrej). Built and maintained at [davidondrej.com](https://davidondrej.com).

---

## What's inside

| Folder | What it is |
|---|---|
| [`awesome-cmux/`](./awesome-cmux) | Curated index of every cmux resource — docs, skills, agents, blog posts, demos. The bookmark you keep open. |
| [`cmux-skill/`](./cmux-skill) | Drop-in skill that teaches any AI coding agent how to drive cmux from the CLI or socket — workspaces, panes, surfaces, browser automation, notifications, and the non-disruptive focus rules. |
| [`cmux-recipes/`](./cmux-recipes) | 20 numbered, copy-paste recipes (CLI + Python + Bash) for the socket API: notify-on-build-fail, flash-on-test-pass, screenshot a browser surface, run three agents on one PR, and more. |

---

## Quick start

```bash
git clone https://github.com/pawel-cell/cmux-ai-agents-bundle.git
cd cmux-ai-agents-bundle

# Wire the cmux skill into Claude Code (or your agent of choice)
mkdir -p ~/.claude/skills/cmux
cp cmux-skill/SKILL.md ~/.claude/skills/cmux/SKILL.md

# Browse the recipes
ls cmux-recipes/
```

> Requires cmux v0.64.0 or newer. Install: `brew tap manaflow-ai/cmux && brew install --cask cmux`

---

## Why this exists

cmux is powerful but the docs are deep. There are 60+ socket methods, a sidebar metadata system, an embedded WKWebView browser, 100+ keyboard shortcuts, and a set of non-obvious "don't steal the user's focus" rules that you only learn by breaking them.

This repo collapses that into:

- one skill your agents can actually load,
- one recipes folder you can `grep` into,
- one awesome-list to find everything else.

Stars and PRs welcome.

---

## Get the rest

This is the public, free version. The full **cmux AI Agents Bundle** at [davidondrej.com](https://davidondrej.com) also includes a guided walkthrough video, prompt templates, and the private "non-disruptive automation" playbook.

→ **Get it free at [davidondrej.com](https://davidondrej.com)**

---

## License

MIT. Use it, fork it, ship it inside your own tools. A link back is appreciated, not required.

## Credits

Built by [pawel-cell](https://github.com/pawel-cell) for [David Ondrej](https://davidondrej.com). cmux is built by [Manaflow](https://manaflow.com). This repo is unaffiliated with Manaflow — just a fan-made companion kit.
