---
tags:
  - 하네스
  - 설정
  - claude-code
updated: 2026-04-28
---

# settings.json 템플릿

`~/.claude/settings.json` 전체 구조 템플릿.
새 환경 세팅 또는 초기화 시 이 파일을 기준으로 작성한다.

---

## 전체 구조

```json
{
  "model": "claude-sonnet-4-6",
  "permissions": {
    "allow": [],
    "additionalDirectories": [
      "<사용자에게 경로 질문 후 채울 것 — 없으면 [] 로 비워둠>"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/pre-commit-doc-check.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/check-source-doc.sh"
          }
        ]
      }
    ]
  }
}
```

---

## 항목별 설명

### `model`

| 값 | 설명 |
|----|------|
| `claude-sonnet-4-6` | 기본값 — 일반 개발·문서 작업 |
| `claude-opus-4-7` | 복잡한 설계·분석 작업 |
| `claude-haiku-4-5-20251001` | 단순 반복·검증 작업 |

> **에이전트 정의 MD 파일** (`~/.claude/agents/*.md`)의 `model:` 필드는 `sonnet`, `opus`, `haiku` 단축명도 사용 가능.
> `settings.json`은 정식 모델 ID를 사용한다.

> Claude Code 내에서 `/model` 명령으로 세션 단위 전환 가능. settings.json은 기본값.

### `permissions.additionalDirectories`

Claude Code가 프로젝트 외부 경로에 접근할 수 있도록 허용 경로를 추가한다.
경로는 사람마다 다르므로 **설정 전 반드시 사용자에게 질문한다.**

```
[에이전트 질문 — additionalDirectories 설정 시 필수]
Q. Claude Code가 프로젝트 외부에서 접근해야 하는 디렉터리가 있나요?
   예: Obsidian Vault 경로, 공유 컨벤션 저장소 등
   실제 경로를 알려주세요. (예: /Users/<사용자명>/Documents/Dev-Vault)
   없으면 "없음"이라고 하면 됩니다.
```

답변을 받은 후 `~/.claude/settings.json`의 `additionalDirectories`에 추가한다.

```json
"permissions": {
  "allow": [],
  "additionalDirectories": [
    "<사용자가 답변한 실제 경로>"
  ]
}
```

| 용도 예시 | 설명 |
|----------|------|
| Obsidian Dev-Vault | 하네스 문서를 읽기 위해 필요 |
| 공유 컨벤션 저장소 | 팀 컨벤션 문서 접근 시 필요 |

> **주의**: `additionalDirectories`에 추가한 경로는 Claude가 Read/Write 가능하다.
> 민감한 디렉터리는 추가하지 않는다.

### `hooks`

훅은 **전역 단위**로 등록한다. 프로젝트별 소스 경로는 `.claude/hooks-config.sh`로 설정한다 (팀 공유 가능). 다중 프로젝트 경로 지원 방법은 `Claude Code/훅_스크립트_전문.md` 참조.

| 필드 | 설명 |
|------|------|
| `matcher` | 도구명 또는 `도구1|도구2` 형식. 정규식 지원. |
| `type` | 현재는 `"command"` 고정 |
| `command` | 실행할 쉘 명령. 스크립트 경로는 절대경로 권장. |

---

## 현재 등록된 훅 요약

| 이벤트 | matcher | 스크립트 | 목적 |
|--------|---------|----------|------|
| `PreToolUse` | `Bash` | `pre-commit-doc-check.sh` | git commit 전 FE·BE 문서 존재 여부 경고 |
| `PostToolUse` | `Edit\|Write` | `check-source-doc.sh` | 소스 파일 수정 후 FE·BE 문서 작성·갱신 유도 |

---

## 현재 상태 확인 명령

```bash
# 등록된 훅 확인
cat ~/.claude/settings.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('hooks', {}), indent=2))"

# 설정 모델 확인
cat ~/.claude/settings.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('model', '(없음)'))"
```

---

## 초기 생성 시

`~/.claude/settings.json`이 없으면 아래 명령으로 최소 구조 생성 후 훅을 추가한다.

```bash
# settings.json이 없을 때만 실행
[ -f ~/.claude/settings.json ] || echo '{}' > ~/.claude/settings.json
```

> **주의**: 기존 파일이 있으면 덮어쓰지 말고 python3 or jq로 병합할 것.

```bash
# 기존 파일에 hooks + additionalDirectories 병합 (python3)
# VAULT_PATH에 사용자가 답변한 경로를 넣어서 실행
VAULT_PATH="/Users/<사용자명>/Documents/Dev-Vault"  # ← 실제 경로로 교체

python3 - << EOF
import json, pathlib

path = pathlib.Path.home() / ".claude" / "settings.json"
data = json.loads(path.read_text()) if path.exists() else {}

# hooks 병합
data.setdefault("hooks", {})
data["hooks"].setdefault("PreToolUse", [])
data["hooks"].setdefault("PostToolUse", [])

pre_cmd = "bash ~/.claude/hooks/pre-commit-doc-check.sh"
if not any(h.get("command") == pre_cmd for block in data["hooks"]["PreToolUse"] for h in block.get("hooks", [])):
    data["hooks"]["PreToolUse"].append({
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": pre_cmd}]
    })

post_cmd = "bash ~/.claude/hooks/check-source-doc.sh"
if not any(h.get("command") == post_cmd for block in data["hooks"]["PostToolUse"] for h in block.get("hooks", [])):
    data["hooks"]["PostToolUse"].append({
        "matcher": "Edit|Write",
        "hooks": [{"type": "command", "command": post_cmd}]
    })

# additionalDirectories 병합 (경로 있을 때만)
vault = "${VAULT_PATH}".strip()
if vault and vault != "없음":
    data.setdefault("permissions", {})
    data["permissions"].setdefault("additionalDirectories", [])
    if vault not in data["permissions"]["additionalDirectories"]:
        data["permissions"]["additionalDirectories"].append(vault)
        print(f"additionalDirectories 추가: {vault}")
    else:
        print(f"이미 등록됨: {vault}")

path.write_text(json.dumps(data, indent=2, ensure_ascii=False))
print("완료:", path)
EOF
```

> **사용 방법**: 스크립트 첫 줄 `VAULT_PATH`에 사용자가 답변한 실제 경로를 넣고 실행한다.
> `additionalDirectories`가 필요 없으면 `VAULT_PATH="없음"` 으로 설정하면 건너뜀.
