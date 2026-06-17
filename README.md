# claude-code-harness

A skill · document · configuration package for applying Claude Code to any software project.

> For Korean documentation see [README.ko.md](./README.ko.md).
> Sister project for design systems / component libraries: [design-harness](https://github.com/Kyungjong-kim/design-harness).

---

## Supported Platforms

| Platform | Support | Notes |
|---|---|---|
| macOS 10.15+ | ✅ | Fully tested |
| Linux (Ubuntu 20.04+) | ✅ | bash 4.0+ required |
| Windows (WSL2) | ✅ | Ubuntu 20.04+ on WSL2 recommended |
| Windows (native) | ✅ | PowerShell 5.1+ via `install.ps1` (real `python` + Git Bash for hooks) |

---

## Quick Start

### 0. Prerequisites

Claude Code 1.x+ and Node.js 18+:

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### 1. Place the harness

Place it at the same level as your project repo:

```
workspace/
  MyProject/    ← your repo
  harness/      ← this folder
```

### 2. Bootstrap

**macOS / Linux / WSL2 (bash):**

```bash
bash harness/install.sh              # project workflow skills (always)
bash harness/install.sh --personal   # + personal productivity skills
bash harness/install.sh --hooks      # + FE doc-check git hooks
```

**Windows native (PowerShell):**

```powershell
powershell -ExecutionPolicy Bypass -File harness\install.ps1            # project workflow skills (always)
powershell -ExecutionPolicy Bypass -File harness\install.ps1 -Personal  # + personal productivity skills
powershell -ExecutionPolicy Bypass -File harness\install.ps1 -Hooks     # + FE doc-check git hooks
powershell -ExecutionPolicy Bypass -File harness\install.ps1 -Yes       # non-interactive (accept defaults)
```

> `install.ps1` is a native port of `install.sh`: it detects the real `python` (skipping the Windows Store `python3` stub), uses `robocopy` instead of `cp`/`rm`, and keeps Korean paths intact in `settings.json`. Hooks register a `bash ...` command, so Git Bash must be on `PATH` for them to fire.

GitHub skills (`/project-fix`, `/project-pr`, `/project-issue`) require GitHub CLI auth:

```bash
gh auth login
```

### 3. Initialize your project

```bash
cd MyProject && claude
```

Then type `/project-init`. Claude analyzes your codebase, asks a few questions, and generates:

- `CLAUDE.md` — STEP 0~3 enforcement loop tailored to your project
- `docs/<project>/agent/` — architecture + conventions docs
- `.claude/agents/` — specialized sub-agents (dev, doc-writer, etc.)
- `HANDOFF_NOW.md` / `HANDOFF.md` / session notes

### 4. Verify

```bash
ls ~/.claude/skills/ | grep -E "project-init|project-fix|session-close|document-review"
gh auth status
```

---

## Upgrading

```bash
bash harness/install.sh --force          # overwrite project skills
bash harness/install.sh --force --hooks  # + hooks
```

```powershell
powershell -ExecutionPolicy Bypass -File harness\install.ps1 -Force         # overwrite project skills
powershell -ExecutionPolicy Bypass -File harness\install.ps1 -Force -Hooks  # + hooks
```

Personal skills (`/daily-note`, `/standup`, etc.) are never overwritten by `--force` / `-Force`.

---

## Skills

### Project workflow (always installed)

| Skill | Purpose |
|---|---|
| `/project-init` | Bootstrap harness for a new project |
| `/project-fix` | Bug / QA issue → sub-issue + branch prep |
| `/project-issue` | Interactive GitHub issue creation |
| `/project-pr` | PR with issue link + Co-Authored-By |
| `/session-close` | End-of-session HANDOFF update (3 files in order) |
| `/document-review` | Scenario-based doc structure & completeness audit |
| `/harness-audit` | Scan harness for dangling agent/skill/doc references |
| `/doc-drift` | Detect feature docs gone stale vs their referenced source |
| `/release-notes` | Milestone release notes → summary issue + deploy announcement |

### Personal productivity (optional, `--personal`)

| Skill | Purpose |
|---|---|
| `/daily-note` | Daily note generation / work log |
| `/standup` | Auto-compose daily standup |
| `/meeting-note` | Structured meeting notes |
| `/til` | Today I Learned entry |
| `/weekly-retro` | Weekly KPT retrospective |
| `/weekly-meeting-update` | Weekly meeting draft |
| `/post-illustrate` | Generate image manifest for a blog post |

---

## Expected Outcomes

`/project-init` creates the **skeleton**. Domain-specific enforcement rules accumulate through operation.

| When | CLAUDE.md lines | Accumulated assets |
|---|---|---|
| Post-bootstrap | ~50 | 4 principles + basic STEP 0~3 |
| After 1 month | ~120 | First pitfall found + domain branches start |
| After 6 months | ~250 | 5~6 domain enforcement rules + evolution history |

See [`examples/`](examples/) for real evolution snapshots (masked & generalized):
- `01-initial.md` — right after bootstrap
- `02-after-1-month.md` — first pitfall added
- `03-after-6-months.md` — full 6-month accumulated example
- `04-team.md` — 2~5 person team sharing pattern

---

## License

MIT — see [LICENSE](./LICENSE).
