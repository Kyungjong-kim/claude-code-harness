---
tags: [하네스, example, evolution, mature]
phase: month-6
generated: (예시 — 6개월 운영 후 시점)
masking: based on real 6-month operation, names anonymized
---

# Acme Platform — Claude Code 하네스 진입점

> **6개월 운영 후.** 작업을 통제하는 하네스. 아래 규칙을 따르지 않으면 작업을 진행하지 않는다.
> 이 문서의 모든 규칙은 **운영하며 발견된 결과물**이다. 부트스트랩 직후엔 이 중 대부분이 없었다.
> 진화 흐름은 문서 하단 §진화 이력 참조.

---

## 🔴 STEP 0 — 작업 시작 전 (건너뜀 금지)

### 0-A. 작업 영역 판별

요청을 받으면 **코드를 건드리기 전에** 작업 대상 영역을 판별한다.
불명확하면 **반드시 사용자에게 먼저 질문한다.** 임의 추정 금지.

| 키워드 / 단서 | 작업 영역 |
|---|---|
| 사용자 포털, user-portal | `user-portal` |
| 관리자, admin, MCP, 워크플로우, [QA]·[admin] 이슈 | `admin-app` |
| 채팅, 사용자 채팅, 보고서, 출처, 스트리밍, 스크롤 | `user-app` |
| AgentService, agent-service, auth-service | `AgentService` |
| API, 백엔드, FastAPI, Python, DB | 백엔드 서비스 |
| Docker, CI/CD, 모노레포, 공통 설정 | 루트/공통 |

불명확 시 질문:
> "이 작업은 user-portal(사용자 포털), admin-app(관리자), 백엔드 중 어느 쪽인가요?"

### 0-B. 진입 문서 로드

| 작업 영역 | 진입 문서 |
|---|---|
| **user-portal** | `user-portal/docs/status/HANDOFF_NOW.md` → 히스토리 필요 시 `user-portal/docs/plans/HANDOFF.md` |
| **admin-app** | `admin-app/docs/status/HANDOFF_NOW.md` → **히스토리 필요 시에만** `admin-app/docs/plans/HANDOFF.md` |

### 0-C. 기존 코드 분석 (코드 작성 전 필수)

유사 기능 파일 **최소 2개 이상** 확인: 경로·컴포넌트 구조·API 호출·상태 관리 방식 파악.
버그 수정 시 생성 화면 vs 수정 화면 동일 기능 구현체 비교 필수.

### 0-D. 구현 계획 수립 (Think Before Coding)

> 가정은 명시적으로 진술. 모호하면 멈추고 질문. 두 해석이 가능하면 둘 다 제시.
> 더 단순한 접근이 보이면 푸시백한다.

분석 결과를 바탕으로 단계별 계획을 수립한 뒤 **사용자에게 제시하고 확인을 받는다.**

```
[구현 계획]
- 수정 대상: <파일 목록>
- 변경 내용: <단계별 작업>
- 영향 범위: <영향받는 기능>
```

**사용자 확인 전까지 코드 작성·파일 수정 금지.** 계획 변경 요청 시 계획을 수정한 뒤 재확인한다.

---

## 🔴 STEP 1 — 작업 중 강제 규칙

| 규칙 | 발견 시점 | 위반 시 |
|---|---|---|
| 이슈 번호 없이 커밋 금지 | M0 | 이슈 먼저 생성 후 커밋 |
| develop에 직접 커밋 금지 | M0 | 브랜치 분기 |
| 커밋은 명시적 요청 시에만 | M0 | 사용자가 "커밋해줘" 전까지 보류 |
| **admin-app: 컴포넌트에서 직접 axios 호출 금지** | M1 | 작업 중단 → `src/api/admin-service/` 레이어 경유로 수정 |
| **user-portal: user-app 소스 미확인 상태에서 API 작업 금지** | M2 | 작업 중단 → `user-portal/docs/guide/user-app_소스_확인_절차.md` 실행 후 재개 |
| **QA/버그 이슈 URL·번호 수령 즉시 서브이슈 없이 작업 금지** | M3 | `/project-fix` 실행 → 서브이슈(Task) 생성 + 브랜치 준비 완료 후 작업 시작 |
| **`[AgentService]` 보존 주석 임의 제거 금지** *(user-portal 전용)* | M4 | `user-portal/docs/guide/API_미확정_user-app_AgentService_병행.md` 확인 후만 허용 |
| **QA 진행 중 추가 버그는 같은 브랜치에 계속 커밋** | M5 | 브랜치 전환 금지 — QA 완료 후 PR 머지 |

> **규칙 우선순위**: 프로젝트별 CLAUDE.md(user-portal·admin-app)에 더 상세한 규칙이 있으면 그것이 우선. 충돌 시 **더 제한적인 것** 적용.

### 협의 대기 상태 처리

협의가 필요해 진행 불가 시: ① 즉시 중단 ② HANDOFF_NOW.md §2에 `⏸ [협의 대기] <작업명> — <협의 내용> / 담당: <팀원명>` 추가 ③ 사용자에게 보고 ④ 독립적인 다른 태스크로 전환. 협의 완료 보고 시 `⏸` 항목 제거 후 재개.

---

## 🔴 STEP 2 — 검증 하네스 (코드 작성 후 필수)

```
[규칙 준수 체크]
- [ ] 기존 파일 구조 준수
- [ ] 기존 코드 스타일 일치
- [ ] API 레이어 패턴 준수                          (M1)
- [ ] 변경된 모든 줄이 사용자 요청에 추적 가능 (Surgical Changes — 인접 코드·포맷팅 임의 정리 없음)
- [ ] 빌드·타입·린트 통과
- [ ] (user-portal) user-app 원본 소스 확인 완료              (M2)
- [ ] (admin-app) disabled 패턴 사용 — 조건부 언마운트 없음     (M3)
- [ ] (QA/버그 이슈) Task 타입 서브이슈 번호로 브랜치·커밋 작업 중인지 (M3)
- [ ] 테스트 작성 여부 확인 (아래 기준 참고)
```

**테스트 작성 기준**:
- 버그 수정·새 비즈니스 로직 함수·훅 → **필수**
- UI 컴포넌트만 변경 → 선택
- 문서·설정만 변경 → 생략

위반 항목 발견 시 즉시 수정. 위반 상태로 완료 처리 금지.

**빌드·타입·린트 오류 시**: ① 내 코드 문제 → 즉시 수정 ② 기존 호환성 문제 → `debugger` 에이전트 ③ 의존성·환경 문제 → `architecture` 에이전트 ④ 2회 이상 반복 실패 → **즉시 중단·사용자 보고**

---

## 🔴 STEP 3 — 세션 종료 강제 절차

코드·문서 변경이 있었던 세션은 사용자 지시 없이도 자동 수행한다.

**공통 갱신 순서 (user-portal·admin-app, 순서 바꾸지 말 것):**
1. `<프로젝트>/docs/status/HANDOFF_NOW.md` — §1 현재 상태·§2 다음 작업 갱신 (60줄 이하 유지)
2. `<프로젝트>/docs/history/세션_노트.md` — 파일 최상단에 `> Session note YYYY-MM-DD: [1~2줄 요약]` prepend  (M1)
3. `<프로젝트>/docs/plans/HANDOFF.md` — `## Session Update YYYY-MM-DD` 섹션 최상단 추가  (M2)
4. **(admin-app 한정)** 관련 기술 문서 `docs/pages/<페이지명>/FE_*.md` 갱신  (M4)

**갱신 후 일관성 검증**: HANDOFF_NOW.md §2 첫 항목이 최신인지 / 60줄 이하인지 / 완료 항목 없는지.

**HANDOFF.md 아카이브 기준**: 월초에 전월 Session Update 전체를 `history/HANDOFF_archive_YYYY.md`로 일괄 이관.

**§2 항목 비대화 기준**: 완료된 항목 → 즉시 삭제 / **2주 이상 미착수 항목 → ⏸ 태그 추가 후 §2 하단으로 이동** / 60줄 초과 시 ⏸ 항목부터 HANDOFF.md로 이관.

**변경 결과 요약 출력 (필수):**
```
[작업 결과]
- 변경 파일:
- 주요 변경:
- 영향 범위:
```

---

## 🔴 코딩 행동 4원칙 (횡단 규칙)

| # | 원칙 | 핵심 행동 | 위반 신호 |
|---|---|---|---|
| 1 | **Think Before Coding** | 가정 명시·모호하면 질문·더 단순한 접근 푸시백 | 추정으로 코드 작성 시작 |
| 2 | **Simplicity First** | 요청한 만큼만·추상화 금지·발생 불가능 시나리오 에러 처리 금지 | "나중에 쓸지도"로 옵션 추가 |
| 3 | **Surgical Changes** | 변경된 모든 줄이 요청에 추적 가능·인접 코드 임의 정리 금지 | 버그 수정 중 주변 포맷팅 정리 |
| 4 | **Goal-Driven Execution** | 검증 가능한 목표로 변환·검증 전 완료 처리 금지 | "되는 것 같다"로 마무리 |

**#2 Simplicity First** — 200줄을 50줄로 줄일 수 있으면 다시 쓴다. 비슷한 줄 3개는 선부 추상화보다 낫다. 검증은 시스템 경계(사용자 입력·외부 API)에서만. 주석은 WHY가 자명하지 않을 때만 한 줄.

**#3 Surgical Changes** — 무관한 dead code 발견 시 삭제 금지·언급만. 본인 변경으로 생긴 미사용 import만 제거. "더 나은 방식"으로 재작성 금지 — 기존 스타일을 따른다.

**#4 Goal-Driven Execution** — 모호한 요청 → 검증 가능한 목표로 변환 ("버그 고쳐" → "재현 테스트 작성 후 통과시키기"). UI 변경은 브라우저 직접 확인 전 완료 금지. 확인 못 했으면 "성공" 금지하고 명시적으로 보고한다.

---

## 서브에이전트 호출 규칙

> **이 프로젝트 오버라이드** — 글로벌 기본을 이 프로젝트 한정으로 덮어쓴다.  (M5)
>
> 1. **isolation: worktree 사용 자제** — 글로벌 기본은 "코드 변경 에이전트 = worktree 필수"이지만 이 프로젝트에서는 명시적 요청 전까지 세션에서 직접 처리.
> 2. **병렬 호출 금지** — 명시적 병렬 요청 없으면 서브에이전트 순차 호출만 허용.
> 3. **test-writer 호출 시** — 프롬프트에 "기존 소스 파일 수정 금지, 테스트 파일만 작성" 명시 필수.

### 단순 작업 → 프로젝트 dev 에이전트 직접 호출

| 작업 유형 | 호출 에이전트 |
|---|---|
| user-portal UI·버그·단순 기능 | `user-portal-dev` |
| admin-app UI·버그·단순 기능 | `admin-app-dev` |
| user-app UI·버그·단순 기능 | `user-app-dev` |
| AgentService UI·버그·단순 기능 | `agent-service-dev` |
| 문서·HANDOFF 갱신 | `doc-writer` |
| 코드 리뷰 | `code-reviewer` |
| 버그 원인 추적 | `debugger` |
| 리팩토링 | `refactor` |
| 테스트 작성 | `test-writer` |

### 복잡·크로스 프로젝트·장기 작업 → master 경유

| 작업 유형 | 호출 에이전트 |
|---|---|
| 타 프로젝트 기능 참조·이식 | `acme-master` |
| 여러 프로젝트 동시 개발 | `acme-master` |
| Phase 단위 장기 작업 | `acme-master` |
| 아키텍처 설계 | `acme-master` → `architecture` |
| 구현 플랜 작성 | `acme-master` → `Plan` |

---

## 팀 프로세스

| 작업 | 참조 문서 |
|---|---|
| 이슈 생성 | `docs/github/ISSUE_CREATION_GUIDE.md` |
| 커밋·브랜치 | `docs/git-workflow/branch-commit.md` |
| PR 생성 | `.github/PULL_REQUEST_TEMPLATE.md` |
| 기술 문서 작성 | `docs/templates/README.md` |

### 브랜치·커밋·PR 핵심 규칙

| 항목 | 규칙 | 예시 |
|---|---|---|
| **브랜치명** | `<타입>/<이슈번호>` — `issue#` 금지, 숫자만 | ✅ `task/001` ❌ `task/issue#001` |
| **브랜치 기준점** | 항상 `develop`에서 생성 | `git checkout develop && git pull` 후 분기 |
| **커밋 메시지** | `<타입>: [FE/BE/공통] 제목 #이슈번호` | `feat: [FE] 권한 체크 제거 #001` |
| **이슈·PR 제목** | `[FE/BE/공통] 제목` (타입 생략) | `[FE] 권한 체크 제거` |
| **PR base** | 항상 `develop` — feature 브랜치 PR 금지 | QA 중 추가 버그는 같은 브랜치에 계속 커밋 |
| **Co-Authored-By** | Claude Code 작업 시 필수 | `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` |

---

## 📈 진화 이력

> **외부 사용자에게 가장 중요한 섹션** — 이 문서가 부트스트랩 출력이 아니라 6개월 운영의 결과물임을 보여줌.

| 시점 | 신규 추가 | 누적 줄 수 |
|---|---|---|
| **M0 (부트스트랩)** | 4원칙 + STEP 0~3 골격 + 팀 프로세스 기본 | ~95줄 (`examples/01-initial.md`) |
| **M1** | STEP 1: admin-app axios 직접 호출 금지 (사고 후) / STEP 3: 세션_노트 prepend (회고 회수 비용 발생 후) | ~110줄 (`examples/02-after-1-month.md`) |
| **M2** | STEP 1: user-portal API 작업 시 user-app 소스 확인 강제 / STEP 3: HANDOFF.md Session Update 도입 / 0-A 도메인 표 점진 확장 (~4영역) | ~140줄 |
| **M3** | STEP 1: QA/버그 이슈 시 서브이슈 강제 (`/project-fix` 도입) / STEP 2: admin-app disabled 패턴·서브이슈 체크 추가 | ~170줄 |
| **M4** | STEP 1: `[AgentService]` 보존 주석 사고 후 강제 규칙 추가 / STEP 3: admin-app 기술 문서 갱신 의무 | ~200줄 |
| **M5** | 서브에이전트 호출 규칙 정착 (worktree 오버라이드·병렬 금지·test-writer 스코프) / QA 동일 브랜치 커밋 규칙 | ~225줄 |
| **M6** | 4원칙 본문 보강 (각 원칙별 1단락 설명) | ~230줄 |
| **M7 (현재) — 다이어트 단계** | 공통 패턴 외부 분리 (FE/BE 진입 베이스·서브에이전트 룰·팀 프로세스를 별도 base 문서로) + 자식 CLAUDE.md 압축 + caveman 압축 프롬프트 도입 → 매 세션 진입 토큰 ~40% 절감 | 루트 ~170줄 + 베이스 문서 분리 |

**부트스트랩 직후엔 이 모든 규칙이 없었다.** 매월 1~2건의 도메인 특정 함정·절차가 누적되어 현재에 이르렀다.

이 문서를 그대로 새 프로젝트에 복사해도 의미 없다 — 그 프로젝트만의 함정은 그 프로젝트가 운영되며 발견되어야 한다. **하네스가 주는 것은 *발견을 기록하는 구조*이지 *발견된 내용 자체*가 아니다.**

> **M7 다이어트 인사이트**: 약 200줄 누적 시점부터 세션 진입 토큰이 부담된다. 이 시점에 공통 패턴(STEP 0~3 골격·서브에이전트 룰·팀 프로세스)을 별도 base 문서로 분리하고, 루트 CLAUDE.md는 진입 체크리스트·도메인 표·금지 규칙만 남긴다. 분리한 base 문서는 자동 로드 대상이 아니라 `🔴 최우선 액션`으로 명시적 Read 시점에 컨텍스트 진입. 자식 CLAUDE.md(모노레포·멀티앱) 상단에도 동일 패턴 적용. 부가로 응답 측 토큰은 caveman 압축 프롬프트로 추가 절감 (`프롬프트/caveman_프롬프트.md`).
