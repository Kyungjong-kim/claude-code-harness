---
tags: [하네스, 설정, mcp, claude-code]
updated: 2026-04-27
---

# MCP 설정_템플릿

`~/.claude/settings.json` 또는 `~/.claude/mcp_settings.json`에 등록하는 MCP 서버 설정.
프로젝트에서 사용하는 MCP만 선택해 등록한다.

---

## 설정 위치

| 위치 | 용도 |
|------|------|
| `~/.claude/settings.json` → `mcpServers` | 전역 등록 — 모든 프로젝트에서 사용 |
| `<project-root>/.mcp.json` | 프로젝트 전용 등록 — 팀 공유 가능 |

---

## 전체 구조 예시

```json
{
  "mcpServers": {
    "playwright": { ... },
    "figma": { ... }
  }
}
```

---

## 서버별 등록 스니펫

### Playwright (UI 자동화·스크린샷)

```json
"playwright": {
  "command": "npx",
  "args": ["@playwright/mcp@latest"],
  "env": {}
}
```

> Claude Code 내 도구명 접두사: `mcp__plugin_playwright_playwright__browser_*`

### Figma (디자인 컨텍스트)

```json
"figma": {
  "command": "npx",
  "args": ["-y", "figma-mcp"],
  "env": {
    "FIGMA_ACCESS_TOKEN": "<토큰>"
  }
}
```

> Claude Code 내 도구명 접두사: `mcp__claude_ai_Figma__*`
> 토큰: Figma → Settings → Personal Access Tokens

### GitHub (이슈·PR 조회·생성)

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "<토큰>"
  }
}
```

### Linear (이슈 트래커)

```json
"linear": {
  "command": "npx",
  "args": ["-y", "linear-mcp-server"],
  "env": {
    "LINEAR_API_KEY": "<API 키>"
  }
}
```

---

## 등록 확인

```bash
# 등록된 MCP 서버 목록
cat ~/.claude/settings.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(list(d.get('mcpServers', {}).keys()), indent=2))"

# Claude Code CLI에서 확인
claude mcp list
```

---

## 프로젝트별 `.mcp.json` (팀 공유용)

프로젝트 루트에 `.mcp.json`을 두면 팀 전원이 동일한 MCP 서버를 사용한다.
민감한 토큰은 포함하지 않고 환경변수 참조로 처리한다.

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

> 토큰이 필요한 서버(Figma, GitHub 등)는 개인 `~/.claude/settings.json`에만 등록하고 `.mcp.json`에는 넣지 않는다.

---

## 에이전트에서 MCP 도구 허용

커스텀 에이전트(`.claude/agents/*.md`)에서 MCP 도구를 사용하려면 프론트매터 `tools` 목록에 명시한다.

```markdown
---
name: my-playwright-validator
tools:
  - mcp__plugin_playwright_playwright__browser_navigate
  - mcp__plugin_playwright_playwright__browser_take_screenshot
  - mcp__plugin_playwright_playwright__browser_click
  - mcp__plugin_playwright_playwright__browser_snapshot
  - Read
  - Bash
---
```

> 도구명은 MCP 서버 등록 시 생성되는 전체 접두사 형식(`mcp__<서버명>__<툴명>`)을 사용한다.
