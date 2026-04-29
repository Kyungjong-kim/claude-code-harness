---
tags: [하네스, claude-code, docs, 디렉토리]
updated: 2026-04-27
---

# docs 디렉토리 구조 가이드

프로젝트 하네스가 의존하는 표준 docs 폴더 구조.
필수 디렉토리와 선택 디렉토리를 구분해 최소 구축부터 시작할 수 있다.

---

## 전체 구조

```
docs/<서비스명>/
│
├── VIBE_CODING_GUIDE.md            ← 【선택】 에이전트·바이브코딩 진입 가이드
│
├── status/                         ← 【필수】 현재 상태 핫 문서
│   └── HANDOFF_NOW.md              ← 세션 시작 시 가장 먼저 읽는 문서 (60줄 이하 유지)
│
├── plans/                          ← 【필수】 세션 히스토리·구현 플랜
│   ├── HANDOFF.md                  ← 세션 단위 변경 이력 누적
│   └── <기능명>_ARCH_DECISION.md   ← 【선택】 아키텍처 결정 기록 (ADR)
│
├── history/                        ← 【필수】 세션 요약 로그
│   └── 세션_노트.md                 ← 1~2줄 세션 요약, 최신→과거 순
│
├── agent/                          ← 【필수】 에이전트 컨텍스트 허브
│   ├── README.md                   ← 이 디렉토리 파일 목록·역할
│   ├── architecture.md             ← 전체 아키텍처 인덱스
│   ├── conventions.md              ← 코딩 컨벤션 요약
│   └── design-system.md            ← 디자인 시스템 규칙 (FE·풀스택 프로젝트)
│
├── pages/                          ← 【필수】 도메인별 기능 정리 문서
│   └── <도메인>/
│       ├── FE_<기능명>.md          ← FE 기능 문서 (훅이 PostToolUse 유도)
│       └── BE_<기능명>.md          ← BE 기능 문서 (BE·풀스택 프로젝트)
│
├── conventions/                    ← 【선택】 코딩 컨벤션 상세
│   ├── README.md
│   └── <컨벤션명>.md
│
├── architecture/                   ← 【선택】 아키텍처 상세 문서
│   ├── README.md
│   └── <구성도명>.md
│
├── guide/                          ← 【선택】 작업 워크플로우 가이드
│   ├── README.md
│   └── <가이드명>.md
│
├── design/                         ← 【선택】 디자인 토큰·Figma 관련
│   └── <디자인문서명>.md
│
├── api/                            ← 【선택】 API 스펙·매핑 문서
│   └── <API문서명>.md
│
├── git-workflow/                   ← 【필수】 브랜치·커밋·PR 가이드
│   ├── branch-commit.md
│   └── pull-request-guide.md       ← 【권장】 PR 생성·리뷰 워크플로우
│
└── testing/                        ← 【선택】 테스트 전략·체크리스트
    └── 동작_확인_체크리스트.md
```

---

## 모노레포 docs 위치 선택

모노레포인 경우 docs 위치를 결정해야 한다. 아래 기준으로 선택한다.

| 구분 | 루트 통합형 | 패키지별 분산형 |
|------|------------|----------------|
| **구조** | `docs/web/`, `docs/admin/` (루트) | `web/docs/`, `admin/docs/` (각 패키지) |
| **훅 관리** | 단일 스크립트로 모든 경로 처리 | 패키지마다 경로 다름 (elif 분기 복잡) |
| **팀 규모** | 소규모 (5인 이하) | 중~대규모 (팀별 독립) |
| **API 공유** | 많음 (공통 문서 활용 유리) | 적음 (패키지 독립적) |

**권장 기준**:
- 팀이 작고 서비스 간 공통 API·컨벤션이 많다 → **루트 통합형**
- 서비스별로 팀이 다르거나 독립 배포된다 → **패키지별 분산형**

```
# 루트 통합형 예시
docs/
├── web-app/       ← 서비스 A
├── admin/         ← 서비스 B
└── mobile/        ← 서비스 C

# 패키지별 분산형 예시
web-app/
└── docs/
admin/
└── docs/
mobile/
└── docs/
```

---

## 각 디렉토리 역할

### 필수 디렉토리

| 디렉토리 | 역할 | 유지 규칙 |
|----------|------|-----------|
| `status/` | 현재 작업 상태 (브랜치·이슈·빌드 명령) | HANDOFF_NOW.md 60줄 이하 |
| `plans/` | 세션별 변경 이력 누적 | 최신 세션이 문서 상단에 |
| `history/` | 세션 1~2줄 요약 | `> Session note YYYY-MM-DD: ...` 형식 |
| `agent/` | 에이전트가 작업 전 읽는 컨텍스트 허브 | 상세 내용은 하위 docs 링크로 |
| `pages/` | 도메인별 기능 정리 문서 (FE: `FE_*.md`, BE: `BE_*.md`) | 훅이 `FE_*.md` / `BE_*.md` 존재 여부 감지 |
| `git-workflow/` | 브랜치·커밋·PR 가이드 | branch-commit.md 항상 포함 |

### 선택 디렉토리

| 디렉토리 | 추가 시기 |
|----------|-----------|
| `conventions/` | 팀 컨벤션이 복잡해질 때 |
| `architecture/` | 시스템 구성도가 필요할 때 |
| `guide/` | 반복 작업 가이드를 문서화할 때 |
| `design/` | Figma 연동·디자인 토큰 관리 시 |
| `api/` | 백엔드 API 스펙 관리 시 |
| `testing/` | E2E·통합 테스트 체크리스트 관리 시 |

---

## 초기 구축 명령 (에이전트용)

```bash
# docs 구조 생성 (프로젝트 루트에서 실행)
# <서비스명> = <서비스명-A> / <서비스명-B> 등
SERVICE=<서비스명>

mkdir -p docs/$SERVICE/{status,plans,history,agent,pages,git-workflow}

# 필수 파일 초기화
touch docs/$SERVICE/status/HANDOFF_NOW.md
touch docs/$SERVICE/plans/HANDOFF.md
touch docs/$SERVICE/history/세션_노트.md
touch docs/$SERVICE/agent/README.md
touch docs/$SERVICE/agent/architecture.md
touch docs/$SERVICE/agent/conventions.md
touch docs/$SERVICE/git-workflow/branch-commit.md
```

---

## pages/ 네이밍 규칙

**FE 프로젝트 예시:**
```
pages/
├── auth/
│   ├── FE_LOGIN.md
│   └── FE_AUTH_CALLBACK.md
├── chat/
│   ├── FE_CHAT_STREAM.md
│   └── FE_CHAT_MAIN_SCREEN.md
└── dashboard/
    └── FE_DASHBOARD.md
```

**BE 프로젝트 예시:**
```
pages/
├── auth/
│   └── BE_AUTH_API.md
├── user/
│   ├── BE_USER_CREATE.md
│   └── BE_USER_PROFILE.md
└── order/
    └── BE_ORDER_FLOW.md
```

- **디렉토리명**: 소문자, 하이픈 구분 (도메인·라우트 단위)
- **FE 파일명**: `FE_` 접두사 + 기능명 대문자 스네이크케이스 + `.md`
- **BE 파일명**: `BE_` 접두사 + 기능명 대문자 스네이크케이스 + `.md`
- **훅 감지 패턴**: `FE_*.md` (FE·풀스택) / `BE_*.md` (BE·풀스택) — 접두사 고정, 이름 자유

---

## HANDOFF_NOW.md 신선도 규칙

- 세션 시작 시 가장 먼저 읽히는 문서 → **항상 현재 상태** 반영
- **60줄 이하** 유지 (넘으면 plans/HANDOFF.md로 이관)
- 세션 종료 시 §1 현재 상태·§2 다음 작업 갱신 필수

## 세션_노트.md 신선도 규칙

- 세션 종료 시 최상단에 prepend (최신이 항상 위)
- 형식: `> Session note YYYY-MM-DD: [1~2줄 요약]`
- 30일 이상 지난 항목은 `history/HANDOFF_archive_YYYY.md`로 이관 (월별 갱신)
