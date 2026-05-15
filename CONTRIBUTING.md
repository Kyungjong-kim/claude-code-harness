---
tags: [하네스, 기여, 가이드]
updated: 2026-05-15
---

# 기여 가이드

## 스킬 수정

스킬을 수정할 때 **하네스 소스 폴더와 `~/.claude/skills/` 양쪽을 함께 갱신**한다.

```bash
# 로컬에서 수정 후 하네스 폴더로 동기화 (프로젝트 스킬)
cp ~/.claude/skills/<스킬명>/SKILL.md \
   하네스/skills/<스킬명>/SKILL.md

# 개인 생산성 스킬인 경우
cp ~/.claude/skills/<스킬명>/SKILL.md \
   하네스/personal-skills/<스킬명>/SKILL.md
```

| 위치 | 역할 |
|------|------|
| `하네스/skills/` | 프로젝트 스킬 소스 오브 트루스 |
| `하네스/personal-skills/` | 개인 스킬 소스 오브 트루스 |
| `~/.claude/skills/` | 실행 위치 — Claude Code가 실제로 읽는 곳 |

## 문서 수정

문서를 수정하면 파일 상단 frontmatter의 `updated` 날짜를 갱신하고 `CHANGELOG.md`에 기록한다.

```markdown
---
updated: YYYY-MM-DD   ← 오늘 날짜로 갱신
---
```

## CHANGELOG 기록 형식

```markdown
## YYYY-MM-DD (N차 — 변경 요약)

### 수정 — 파일명
- `경로/파일명` — 변경 내용 한 줄 요약
```

## 이슈 제보

버그·개선 요청은 GitHub Issues로 제보한다.

> **배포 전 필수**: 이 섹션에 실제 GitHub 레포 URL을 추가한다.
> 예: `https://github.com/<owner>/<repo>/issues`

- **버그**: 재현 방법 + 기대 동작 + 실제 동작 + 환경 정보 (OS, Claude Code 버전)
- **기능 요청**: 문제 상황 + 원하는 동작 + 대안 검토 여부

## 훅 스크립트 수정

훅을 수정하면 `hooks/` 소스 파일과 `Claude Code/훅_스크립트_전문.md` 코드블록을 함께 갱신한다.

```bash
# 로컬 훅 수정 후 하네스로 동기화
cp ~/.claude/hooks/check-source-doc.sh       하네스/hooks/check-source-doc.sh
cp ~/.claude/hooks/pre-commit-doc-check.sh   하네스/hooks/pre-commit-doc-check.sh
```

## 커밋 author·식별 정보 정책

본 레포는 OSS다. 커밋 author·이메일·Co-Authored-By 라인은 영구 공개 기록으로 남는다. 본인 또는 기여자가 노출할 정보의 범위를 의식적으로 결정한다.

### 메인테이너 정책

| 항목 | 정책 |
|---|---|
| **커밋 author 이름** | GitHub 핸들 또는 일반 이름 — 풀네임·실명 자유 |
| **커밋 author 이메일** | 개인 이메일 또는 GitHub `noreply` 이메일 (`<id>+<handle>@users.noreply.github.com`) |
| **회사 이메일 사용 금지** | 회사 도메인 이메일로 커밋 시 사내 작업물과 외부 OSS 활동이 동일 attribution으로 묶임. 사용 금지 |
| **Co-Authored-By Claude** | AI 협업 명시. 본인 작업물은 `Co-Authored-By: Claude <noreply@anthropic.com>` 라인 포함 권장. 단, 개인 OSS 영역은 단독 커미터로 진행 (정책상 선택). |

### 기여자(외부 PR) 정책

| 항목 | 가이드 |
|---|---|
| 커밋 author | 본인이 선호하는 이름·이메일 사용. GitHub noreply 이메일 권장 (개인 정보 보호) |
| 회사 자산·식별 노출 | 회사 코드·디렉터리 경로·내부 이슈번호 등 PR 포함 금지. 일반화·마스킹 후 제출 |
| AI 생성 코드 | 커밋 메시지 본문 또는 `Co-Authored-By` 라인으로 명시 (선택) |

### git 멀티계정 설정 (메인테이너용)

개인·업무 GitHub 계정 분리 운영자는 디렉터리 기준 자동 분리 권장:

```bash
# ~/.gitconfig
[user]
  name = <업무 기본>
  email = <업무 이메일>

[includeIf "gitdir:~/projects/"]
  path = ~/.gitconfig-personal
[includeIf "gitdir:~/Documents/Dev-Vault/Dev-Vault/code-harness/"]
  path = ~/.gitconfig-personal
```

```bash
# ~/.gitconfig-personal
[user]
  name = <개인 GitHub 핸들>
  email = <개인 이메일 또는 noreply>
```

origin URL은 SSH alias로 분리하면 `gh auth` 활성 계정과 독립하여 push 가능:

```bash
git remote set-url origin git@github-personal:<handle>/<repo>.git
```

SSH config 예시:

```
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
```
