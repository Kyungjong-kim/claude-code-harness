---
tags: [하네스, examples, 팀]
updated: 2026-05-07
---

# Example — 팀(2~5인) 하네스 공유 패턴

> **시나리오**: 2인 팀(A·B)이 같은 레포를 작업할 때 하네스를 어떻게 공유하는가.
> `--local` 설치 + `hooks-config.sh` + HANDOFF_NOW.md를 팀 비동기 소통 도구로 활용하는 패턴.

---

## 1. 적용 환경

| 항목 | 값 |
|---|---|
| **팀 규모** | 2인 (엔지니어 A · 엔지니어 B) |
| **레포** | `acme-web` (Next.js 15 + TypeScript, 모노레포) |
| **이슈 트래커** | GitHub Issues |
| **브랜치 전략** | `develop` 기반 기능 브랜치 |
| **하네스 버전** | v1.1.0 |

---

## 2. 팀 공유 설치 방법 — `--local` 모드

**1인 혼자 설치할 때**와의 차이: `--local` 플래그를 쓰면 스킬이 `~/.claude/skills/`(개인) 대신 `.claude/skills/`(레포 내)에 설치된다. 이 폴더를 git으로 추적하면 팀원이 `git clone` 후 바로 스킬을 쓸 수 있다.

**엔지니어 A가 처음 설치하는 경우:**

```bash
cd acme-web
bash ~/하네스/install.sh --local --hooks
```

결과:
```
.claude/
  skills/
    project-init/SKILL.md
    project-fix/SKILL.md
    project-issue/SKILL.md
    project-pr/SKILL.md
    session-close/SKILL.md
    document-review/SKILL.md
  settings.json         ← 팀 공통 설정 (모델·훅 등록)
  hooks-config.sh       ← /project-init이 생성, 소스 경로 정의
```

```bash
git add .claude/skills/ .claude/settings.json .claude/hooks-config.sh
git commit -m "chore: add claude-code-harness local install"
```

**엔지니어 B가 합류하는 경우:**

```bash
git pull   # .claude/ 폴더 수신
# 끝. 스킬 즉시 사용 가능
claude  # 열면 /project-init, /project-fix 등 바로 인식
```

> **훅 스크립트는 개별 설치 필요**: `pre-commit-doc-check.sh`는 `~/.claude/hooks/`(개인 경로)에 있어야 하므로, 팀원 각자가 1회 실행:
> ```bash
> bash ~/하네스/install.sh --hooks
> ```
> 훅 설정(`.claude/hooks-config.sh`)은 레포에 공유되어 있으므로 경로 재설정은 불필요.

---

## 3. HANDOFF_NOW.md — 팀 비동기 소통 도구

단독 운영에서 HANDOFF_NOW.md는 "내가 어디까지 했나" 기록이다. 팀에서는 **비동기 인계 문서**가 된다.

### 운영 규칙 (팀)

1. 세션 종료 시 `/session-close` 실행 → HANDOFF_NOW.md §1·§2 갱신
2. 다음 날 세션 시작 전 팀원의 HANDOFF_NOW.md §1 확인
3. 충돌 가능한 작업 영역이 겹치면 Slack/이슈에서 먼저 조율

### HANDOFF_NOW.md 팀 패턴 예시

```markdown
## §1 현재 상태

- **브랜치**: feat/1234 (A 작업 중)
- **마지막 세션**: 2026-05-07 A — 로그인 폼 API 연결 완료
- **다음 작업자**: B — 대시보드 컴포넌트 분리 (#1235)

## §2 다음 작업

### A 담당
- [ ] #1234 — 소셜 로그인 추가 (5/8 예정)

### B 담당
- [ ] #1235 — 대시보드 차트 컴포넌트 분리 (오늘)
- [ ] #1236 — 모바일 반응형 수정

### 협의 대기
- ⏸ 에러 핸들링 공통 레이어 설계 — A·B 둘 다 영향. 5/9 같이 논의
```

---

## 4. 서브에이전트 — 팀 도메인별 에이전트 분리

팀이 커지면 `/project-init`이 만든 에이전트를 도메인별로 세분화한다.

**혼자일 때:**
```
~/.claude/agents/
  acme-web-dev.md          # 단일 에이전트
  acme-web-doc-writer.md
```

**2인 이상일 때 (도메인 분리):**
```
~/.claude/agents/
  acme-web-auth-dev.md     # A 담당 — 인증 도메인
  acme-web-dashboard-dev.md# B 담당 — 대시보드 도메인
  acme-web-doc-writer.md   # 공용
```

각 에이전트에 "이 에이전트는 auth 도메인만 수정한다" 강제 규칙 추가:

```markdown
# acme-web-auth-dev 에이전트

## 작업 범위 제한
- 수정 가능: `src/features/auth/`, `src/api/auth.ts`, `docs/acme-web/pages/auth/`
- 수정 금지: 다른 도메인 파일. 필요 시 acme-web-dashboard-dev 에이전트 호출
```

---

## 5. hooks-config.sh — 팀 공유 훅 설정

`/project-init` 실행 후 생성되는 `.claude/hooks-config.sh`는 각자 환경에서 다른 경로를 쓰면 깨진다. 팀 공통 패턴은 **상대 경로 + 환경 변수**로 관리한다:

```bash
# .claude/hooks-config.sh (git 추적)
export FE_PATTERN="src/"
export DOCS_ROOT="docs/acme-web/pages"
export FE_DOC_PREFIX="FE_"
# 절대 경로 대신 상대 경로 사용 — 팀원 환경 호환
```

`pre-commit-doc-check.sh`가 이 파일을 source해 경로를 읽으므로, 각자 절대 경로를 따로 설정할 필요가 없다.

---

## 6. 개인 생산성 스킬 — 개인 설치, 팀 공유 안 함

`/daily-note`, `/standup` 등 개인 스킬은 각자 노트 경로가 달라서 팀 공유 대상이 아니다.

```bash
# 각자 개별 설치 (1회)
bash ~/하네스/install.sh --personal
# 노트 경로: /Users/<각자 경로>/Documents/Dev-Vault 등
```

레포의 `.claude/skills/`에는 프로젝트 스킬만 포함됨을 `.gitignore`로 보장한다:

```
# .gitignore (예시)
.claude/skills/daily-note/
.claude/skills/standup/
.claude/skills/weekly-retro/
.claude/skills/til/
.claude/skills/meeting-note/
.claude/skills/weekly-meeting-update/
```

---

## 7. 팀 적용 체크리스트

- [ ] A가 `--local --hooks` 설치 후 `.claude/` 커밋
- [ ] B가 pull 후 `bash ~/하네스/install.sh --hooks` (훅 스크립트 개인 설치)
- [ ] `/project-init` 실행 (1회, 공통 CLAUDE.md + HANDOFF 구조 생성)
- [ ] HANDOFF_NOW.md §1에 "담당" 컬럼 추가 (팀 패턴)
- [ ] 에이전트 파일 도메인별 분리 (선택, 3인 이상 권장)
- [ ] `.gitignore`에 개인 스킬 경로 추가
