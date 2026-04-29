---
tags: [하네스, example, evolution]
phase: month-1
generated: 2026-XX-XX
---

# Acme Platform — Claude Code 하네스 진입점

> **1개월 운영 후.** 첫 함정 발견·도메인 분기 2개 정착.
> 빈 자리가 채워지기 시작한 상태.

---

## 🔴 STEP 0 — 작업 시작 전

### 0-A. 작업 영역 판별

| 키워드 / 단서 | 작업 영역 |
|---|---|
| 사용자 포털, user-portal | `user-portal` |
| 관리자, admin, [admin] 이슈 | `admin-app` |

> 4영역까진 아직 정착 안 됨. 2영역만 명확. 나머지는 모호 시 질문.

### 0-B. 진입 문서 로드

| 작업 영역 | 진입 문서 |
|---|---|
| user-portal | `user-portal/docs/status/HANDOFF_NOW.md` |
| admin-app | `admin-app/docs/status/HANDOFF_NOW.md` |

### 0-C. 기존 코드 분석

유사 기능 파일 최소 2개 이상 확인.

### 0-D. 구현 계획 수립

분석 결과를 바탕으로 단계별 계획을 수립한 뒤 사용자에게 제시하고 확인을 받는다.

---

## 🔴 STEP 1 — 작업 중 강제 규칙

| 규칙 | 발견 시점 | 위반 시 |
|---|---|---|
| 이슈 번호 없이 커밋 금지 | M0 | 이슈 먼저 생성 |
| develop에 직접 커밋 금지 | M0 | 브랜치 분기 |
| 커밋은 명시적 요청 시에만 | M0 | 사용자가 "커밋해줘" 전까지 보류 |
| **admin-app: 컴포넌트에서 직접 axios 호출 금지** | **M1 — API 레이어 패턴 깨짐 사고 후 추가** | 작업 중단 → `src/api/` 레이어 경유로 수정 |

> M1 발견 배경: admin-app의 한 페이지에서 직접 `axios.get()` 호출 → 후속 작업에서 인증 헤더 누락으로 401. 이후 모든 컴포넌트 axios 직접 호출 금지·API 레이어 강제.

---

## 🔴 STEP 2 — 검증 하네스 (코드 작성 후 필수)

```
[규칙 준수 체크]
- [ ] 기존 파일 구조 준수
- [ ] API 레이어 패턴 준수            ← M1 추가
- [ ] 상태 관리 방식 일치
- [ ] 변경된 모든 줄이 사용자 요청에 추적 가능 (Surgical Changes)
- [ ] 테스트 작성 여부 확인
```

---

## 🔴 STEP 3 — 세션 종료

코드·문서 변경이 있었던 세션은 사용자 지시 없이도 자동 수행한다.

1. `<프로젝트>/docs/status/HANDOFF_NOW.md` §1·§2 갱신 (60줄 이하 유지)
2. **`<프로젝트>/docs/history/세션_노트.md` 최상단 prepend** ← M1 추가 (이력 추적 필요성 발견)

> M1 추가 배경: 2주 후 회고 때 "지난 주 무엇을 했더라" 회수 비용 발생. 이후 매 세션 한 줄 prepend 강제.

---

## 🔴 코딩 행동 4원칙

| # | 원칙 | 핵심 행동 |
|---|---|---|
| 1 | Think Before Coding | 가정 명시·모호하면 질문 |
| 2 | Simplicity First | 요청한 만큼만·추상화 금지 |
| 3 | Surgical Changes | 변경된 모든 줄이 요청에 추적 가능 |
| 4 | Goal-Driven Execution | 검증 가능한 목표로 변환 |

---

## 팀 프로세스

| 항목 | 규칙 | 예시 |
|---|---|---|
| 브랜치명 | `<타입>/<이슈번호>` | `task/001` |
| 브랜치 기준점 | 항상 `develop`에서 생성 | |
| 커밋 메시지 | `<타입>: [FE/BE/공통] 제목 #이슈번호` | `feat: [FE] 권한 체크 추가 #001` |
| PR base | 항상 `develop` | |
| Co-Authored-By | Claude Code 작업 시 필수 | `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` |

---

## 진화 메모 (M0 → M1)

- M0 → M1 사이 줄 수: 약 50줄 → 약 120줄
- 신규 강제 규칙: 1건 (axios 직접 호출 금지)
- 신규 절차: 1건 (세션_노트 prepend)
- 작업 영역 표: 0개 → 2개 항목

운영 1개월에 누적된 양. 함정 1건 + 절차 1건이면 정상 페이스.
