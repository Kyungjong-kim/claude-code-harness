---
tags: [하네스, 템플릿, git, 워크플로우]
updated: 2026-04-27
---

# Git 워크플로우 템플릿

`docs/<서비스명>/git-workflow/branch-commit.md` 에 위치하는 팀 Git 규칙 문서 템플릿.

> **에이전트 사용 안내**
> 1. 이 템플릿을 `docs/<서비스명>/git-workflow/branch-commit.md`에 복사한다.
> 2. 아래 질문에 사용자가 답하면 `<!-- FILL -->` 구간을 채운다.
> 3. 채운 내용은 CLAUDE.md의 "브랜치·커밋 핵심 규칙" 섹션과 일치시킨다.

---

## 초기 구축 시 에이전트 질문 목록

```
Q1. 브랜치 전략은 무엇인가요?
    A) GitHub Flow (main + feature 브랜치만)
    B) Git Flow (main + develop + feature/release/hotfix)
    C) 커스텀

Q2. 기본 브랜치(PR 대상)는 무엇인가요?
    예: main / develop / master

Q3. 브랜치 네이밍 규칙이 있나요?
    예: feature/이슈번호, task/이슈번호, fix/이슈번호

Q4. 커밋 메시지 접두사 규칙이 있나요?
    예: [FE] / [BE] / [공통], feat: / fix: / docs:, 없음

Q5. 이슈 트래커가 무엇인가요?
    A) GitHub Issues  B) Linear  C) Jira  D) 없음 (1인 운영·소규모 OSS 등)

Q6. PR 시 이슈 연결 방식은?
    예: Closes #이슈번호, Fixes #이슈번호, 없음 (Q5=D인 경우 자동으로 "없음")

Q7. Claude Code 작업 시 Co-Authored-By 커밋 서명을 사용하나요?
    예: 예 / 아니오

Q8. 영역 브래킷(예: [FE]/[BE]/[공통])을 사용하나요?
    A) 예 — 다중 패키지·풀스택 구분이 필요한 프로젝트
    B) 아니오 — 단일 패키지(단일 앱·단일 서비스)는 영역 구분 불필요. 컨벤셔널 커밋(`feat:`)만 사용
```

---

<!-- 아래부터 실제 branch-commit.md 내용 -->

# [서비스명] 브랜치·커밋 가이드

---

## 브랜치 전략

<!-- FILL: Q1·Q2 답변 기반 -->

**전략**: [GitHub Flow / Git Flow / 커스텀]

```
[main/develop]
    └── [feature/task/fix]/[이슈번호]    ← 작업 브랜치
```

**생성 기준점**: 항상 `[main/develop]`에서 분기

```bash
git checkout [main/develop]
git pull origin [main/develop]
git checkout -b [타입]/[이슈번호]
```

---

## 브랜치 네이밍

<!-- FILL: Q3 답변 기반 -->

| 타입 | 패턴 | 예시 |
|------|------|------|
| 기능 개발 | `[타입]/[이슈번호]` | `task/1234` |
| 버그 수정 | `fix/[이슈번호]` | `fix/1235` |
| 핫픽스 | `hotfix/[이슈번호]` | `hotfix/1236` |

**금지 패턴**: `issue#1234` (# 사용 금지), 이슈 번호 없이 브랜치 생성 금지

---

## 커밋 메시지 규칙

<!-- FILL: Q4·Q8 답변 기반

  Q8=A (영역 브래킷 사용): `<타입>: [영역] 작업 내용 #이슈번호`
  Q8=B (영역 브래킷 미사용 — 단일 패키지): `<타입>: 작업 내용 [#이슈번호 — Q5=D면 생략]`

  Q5=D (이슈 트래커 없음)일 때:
  - `#이슈번호` 생략
  - "이슈 번호 없이 커밋 금지" 규칙도 비활성화 (CLAUDE.md STEP 1에서도 동일하게 처리)
  - 추후 이슈 트래커 도입 시 이 문서 + CLAUDE.md 함께 갱신
-->

**형식**: `<타입>: [영역] 작업 내용 #이슈번호`

### 변경 타입 목록 (브랜치명·커밋 메시지 공통)

| 타입 | 브랜치 예 | 설명 |
|------|----------|------|
| `feat` | `feat/1234` | 새로운 기능 추가 |
| `fix` | `fix/1234` | 버그 수정 |
| `task` | `task/1234` | 일반 작업 (기능 외 개발, 개선) |
| `docs` | `docs/1234` | 문서 추가·수정 |
| `refact` | `refact/1234` | 코드 리팩토링 |
| `style` | `style/1234` | 코드 의미에 영향을 주지 않는 변경 |
| `chore` | `chore/1234` | 빌드·패키지·설정·환경 변경 |
| `test` | `test/1234` | 테스트 코드 추가·수정 |

### 영역 브래킷 선택 기준

| 영역 | 사용 시 |
|------|---------|
| `[FE]` | 프론트엔드 변경 |
| `[BE]` | 백엔드 변경 |
| `[공통]` | 설정·문서·공통 변경 |

**예시**:
```
feat: [FE] 채팅 스트림 중지 버튼 추가 #1234
fix: [BE] 사용자 인증 토큰 만료 처리 #1235
chore: [공통] ESLint 설정 업데이트 #1236
```

> **이슈·PR 제목**은 타입 생략: `[FE] 채팅 스트림 중지 버튼 추가`

<!-- FILL: Q7 답변이 "예"인 경우 포함 -->
**Claude Code 작업 커밋 서명** (필수):
```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## 이슈 연결

<!-- FILL: Q5·Q6 답변 기반 -->

**이슈 트래커**: [GitHub Issues / Linear / Jira]

PR body 첫 줄에 반드시 포함:
```
Closes #이슈번호
```

이슈 없이 PR·커밋 금지. 이슈가 없으면 먼저 생성 후 진행.

---

## PR 가이드

<!-- FILL: 팀 PR 프로세스에 맞게 수정 -->

**PR 대상 브랜치**: `[main/develop]`

**PR 제목 형식**: `[영역] 기능 설명 #이슈번호` (타입 생략 — 커밋 메시지와 다름)

**체크리스트**:
- [ ] 기능 동작 로컬 확인
- [ ] 린트·타입 체크 통과 (`[린트 명령]`)
- [ ] 테스트 통과 (해당 시)
- [ ] 관련 문서 갱신 (FE_*.md, HANDOFF_NOW.md)

---

## .gitignore 하네스 관련 항목

<!-- FILL: 팀 합의에 따라 추적 여부 결정 -->

```gitignore
# Claude Code 개인 설정 (팀 공유 안 함)
CLAUDE.md
.claude/settings.json
.claude/settings.local.json

# 로컬 전용 스킬 패키지
*.skill

# 스크린샷·로컬 테스트 결과
**/docs/testing/screenshots/
*.png
```

> **팀 공유 여부 결정 기준**:
> - `CLAUDE.md` — 팀 공유가 필요하면 gitignore 제외 (프로젝트 정책에 따라 결정)
> - `.claude/agents/` — 프로젝트 전용 에이전트는 공유 가능 (팀 합의)
> - `.claude/skills/` — 공유 스킬은 추적, `.skill` 빌드 파일은 제외
