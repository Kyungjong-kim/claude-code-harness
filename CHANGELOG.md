---
tags: [하네스, changelog]
updated: 2026-06-18
---

# CHANGELOG

하네스 문서·스킬·스크립트의 주요 변경 이력.

---

## 2026-06-18 (40차 — Windows 네이티브 설치기 install.ps1, v1.3.0)

> Windows native(비 WSL) 환경에서 `install.sh`가 동작하지 않는 문제 해소. PowerShell 포팅 추가.

### 신규 — install.ps1 (Windows PowerShell 부트스트랩)
- `install.sh`의 5단계(의존성·스킬·개인스킬·settings.json·훅)를 PowerShell 5.1+로 1:1 포팅.
- 플래그: `-Local` `-Personal` `-Hooks` `-Force` `-Dir` `-NotePath` `-Yes`(비대화형).
- **Windows 함정 회피:**
  - `python3` → Windows Store 스텁(`WindowsApps`, exit 49)이라 실제 실행 불가. `Find-RealPython`이 스텁을 걸러 실제 `python`/`py -3` 탐지.
  - `cp`/`rm` 대신 `robocopy /MIR` — Copy-Item 중첩·Remove-Item 가드 회피, 디렉터리 정확 미러.
  - python JSON 편집을 stdin 파이프 대신 임시 UTF-8 `.py`로 실행 + 인자 전달 → 한글 경로 손상·빈 인자 드롭 방지, `settings.json` 한글 그대로 보존.
  - 콘솔/파이썬 UTF-8 강제(`PYTHONUTF8`)로 한글 출력 깨짐 방지.
- 훅 등록 command는 `bash ...` 유지 — 발동하려면 `PATH`에 Git Bash 필요(README 명시).

### 변경
- README.md·README.ko.md 지원 플랫폼 표: Windows (native) ✗ → ✅ + Windows 부트스트랩/업그레이드 섹션 추가
- README 개인 스킬 표에 `/post-illustrate` 추가
- VERSION 1.2.0 → 1.3.0

---

## 2026-06-16 (39차 — 자가검증·릴리스 스킬 3종 추가, v1.2.0)

> 운영 하네스에서 검증된 개선 패턴을 공용 하네스로 이식.

### 신규 — skills/harness-audit
- 하네스 끊긴 배선 스캔: 삭제·리네임된 에이전트/스킬/문서 참조, 없는 경로, 고아 에이전트 탐지.
- 읽기 전용. 모든 쉘(bash·zsh·sh) 호환(`while IFS= read -r` 파이프, process substitution·`for x in $var` 미사용).

### 신규 — skills/doc-drift
- 기능 문서(FE_*.md·BE_*.md)가 참조 source보다 노후됐는지 git 이력 비교로 탐지.
- 모노레포 패키지 prefix 해소(`resolve()`), 임시파일 redirect로 POSIX 호환.

### 신규 — skills/release-notes
- 마일스톤 배포 내역 → 사용자-대면 큐레이션 → 요약 이슈 + 배포 공지 메시지(부모→하위 불렛+이슈번호).
- 공지 자동 게시 없이 복사용 텍스트만 출력.

### 변경
- README.md·README.ko.md Skills 표에 3종 추가
- VERSION 1.1.0 → 1.2.0

---

## 2026-05-15 (38차 — 다이어트 + caveman 압축 프롬프트 + author 정책)

### 신규 — 프롬프트/caveman_프롬프트.md
- plugin·hook 없이 동작하는 압축 모드 단일 프롬프트 (129줄)
- 적용 3가지: CLAUDE.md 상단 / SessionStart hook / 슬래시 커맨드
- 강도 lite·full·ultra 3단계. 한국어·영어 예시 포함

### 변경 — 공용_하네스_구축_가이드.md (다이어트)
- 393 → 275줄 (-30%) 진입 가이드 슬림화
- "스킬 업데이트 규칙" → `운영_가이드/스킬_업데이트_규칙.md` 신규 분리 (32줄)
- "수동 구축 (install.sh 없이)" → `운영_가이드/수동_구축_절차.md` 신규 분리 (99줄)
- 분리 문서 상단 🔴 진입 가이드 참조 헤더 명시
- 관련 문서 섹션에 caveman·수동구축·스킬업데이트 3종 링크 추가

### 신규 — 운영_가이드/수동_구축_절차.md
- install.sh 사용 불가 환경의 Phase 1~4 수동 부트스트랩 절차

### 신규 — 운영_가이드/스킬_업데이트_규칙.md
- 하네스 소스 ↔ ~/.claude/skills/ 양방향 동기화 + 주의사항

### 변경 — examples/03-after-6-months.md
- 진화 표 M7 행 추가 — 약 200줄 누적 시점 공통 패턴 외부 분리 + 자식 CLAUDE.md 압축 + caveman 압축 프롬프트
- 본문 말미 "M7 다이어트 인사이트" 단락 추가
- M5 narrative 본인 실제 경험과 일치하도록 수정 — "worktree 사용 자제" → "worktree 적극 사용 (병렬 이슈 처리·파일 충돌 회피)"
- M5 진화 표 행 동기화
- 어댑터 디렉터리 명명 일관화 — `src/api/admin-service/`로 통일 (`admin-app`(FE) ↔ `admin-service`(BE) 매칭)

### 변경 — CONTRIBUTING.md
- 커밋 author·식별 정보 정책 섹션 추가
- 회사 이메일 사용 금지 명시
- 메인테이너용 git 멀티계정 설정 + SSH alias 분리 가이드

---

## 2026-04-30 (37차 — v1.1.0 — 시뮬레이션 결과 보강 + 라이브러리 분리 결정)

> 외부자 시뮬레이션(라이브러리 프로젝트 적용) 결과 발견된 6개 갭(G1·G2·G4·G5·G11·G12)을 본체에 반영. 라이브러리·CLI 등 다른 프로젝트 유형은 본체에 분기로 넣지 않고 별도 OSS(`design-harness`)로 분리하기로 결정.

### 변경 — install.sh
- (G1) 출력 깨짐 수정 — `→ 복사·갱신 $COPIED개` 의 `$COPIED개` 변수 확장 실패 → `${COPIED}개` 로 명시 (3곳)
- (G2) `--local` 모드 완료 메시지의 검증 명령이 글로벌 경로(`~/.claude/skills/`)를 안내하던 것을 분기 처리 → `--local` 이면 `.claude/skills/` 안내

### 변경 — skills/project-init/SKILL.md
- (G4) Step 3 — 기존 `docs/` 자료가 있을 때 사용자에게 명시적으로 처리 옵션 묻기 (그대로 두기 / history 이관 / 직접 정리 / 기존 경로 유지). 자동 처리 금지
- (G5) Step 1 — 모노레포 감지 로직에 `pnpm-workspace.yaml` 추가 (현재·상위 디렉터리 모두). 파악 항목 표에도 반영

### 변경 — Claude Code/템플릿/git_워크플로우_템플릿.md
- (G11) Q5 이슈 트래커 옵션 D "없음" 명시 (1인 OSS·소규모 운영). Q5=D면 `#이슈번호` 생략 + "이슈 번호 없이 커밋 금지" 규칙 비활성화
- (G12) Q8 신규 — 영역 브래킷(`[FE]/[BE]/[공통]`) 사용 여부 옵션화. 단일 패키지면 `<타입>: 작업 내용` 형식만 사용

### 결정 — 라이브러리·디자인시스템 OSS 분리
- 외부자 시뮬레이션에서 발견한 라이브러리 분기 갭(G3·G6·G8·G9·G10)은 본체에 통합하지 않음
- 별도 OSS `design-harness` (또는 추후 `cli-harness`)로 분리 — 도메인이 거의 겹치지 않고 본체 SKILL.md 부풀림 방지가 목적
- 본체는 앱(FE·BE·풀스택) 중심으로 깔끔하게 유지

---

## 2026-04-29 (36차 — OSS 준비 — 마스킹·examples·문서 정비)

### 추가 — examples/
- examples/ 디렉토리 신설 — README + 01-initial(50줄) + 02-after-1-month(120줄) + 03-after-6-months(250줄, 본인 6개월 운영 사례 마스킹·일반화)

### 추가 — README.md
- "기대치 설정" 섹션 — M0/M1/M6 줄수 비교 표 + examples/ 진화 흐름 안내
- "실행 흐름 예시" 3종 — install.sh / `/project-init` Q&A / `/daily-note` 콘솔 출력

### 변경 — 운영_가이드/코딩_원칙.md
- "하네스 STEP으로 풀어 쓰면" / "내 하네스로 풀어 쓰면" 섹션 4개 통째 제거
- 4원칙 표의 "내 하네스 매핑" 컬럼 제거 + §출처 섹션 제거
- 297줄 → 199줄 슬림화. 운영 실무는 examples/03 + 다른 운영_가이드 문서로 위임

### 변경 — Claude Code/훅_스크립트_전문.md
- pre-commit-doc-check.sh: BLOCKED_BRANCHES 환경변수 분리 (default `develop|main|master`, hooks-config.sh로 customize 가능)
- hooks-config.sh source 위치를 STAGED 체크 직후로 이동 (보호 브랜치 체크 전)

### 변경 — 운영_가이드/팀_훅_설정_공유.md
- hooks-config.sh 예시에 BLOCKED_BRANCHES 안내 추가

### 변경 — 운영_가이드/HANDOFF_유지_규칙.md
- agent/ 문서 갱신 규칙에 안내 추가 (`/project-init` 자동 생성 + 템플릿 참조)

### 변경 — 운영_가이드/세션_패턴_모음.md
- 마스터 오케스트레이터 정의 footnote (`<프로젝트>-master` 명명 + 자동 생성 안내)

### 변경 — Claude Code/개요.md
- L67 "내 하네스 통합 운영 가이드" → "STEP 0~3 운영 매핑" 일반화

### 변경 — 프롬프트/서브에이전트_호출_패턴.md
- 머리말 "📌 내부 문서 / 제작자의" → "📌 참고 문서 / 운영자가" 일반화

### 변경 — 설정_템플릿/settings.json_템플릿.md
- VAULT_PATH 예시 "홍길동" → "<사용자명>" placeholder (2곳)

### 수정 — 내부 식별자·도메인 풀이 마스킹 25건
- 운영_가이드/코딩_원칙.md 16건 — 도메인 풀이 제거 + examples/03 참조로 갈음
- Claude Code/트러블슈팅.md 7건 — 내부 프로젝트명 → 일반 경로명 치환
- CHANGELOG.md 1건 (122줄) — 내부 에이전트 명명 → `agent-service-dev` 일반화
- personal-skills/skills/ 12개 SKILL — grep 0 클린 확인

### 기타 — git 관리 시작
- `Dev-Vault/code-harness/` git init + 첫 커밋 `a8f73b2` (68개 파일 tracked, main 브랜치)
- GitHub private push는 보류 — review 후 안전하게 진행

---

## 2026-04-28 (35차 — 패키지별 실행 시 전역 에이전트 오탐 수정)

### 수정 — skills/project-init/SKILL.md
- Step 0 재실행 감지 스크립트에서 전역 에이전트(`~/.claude/agents/`)를 PARTIAL 판정에서 제외 (🟡 혼동)
  - 모노레포에서 패키지별 실행 시, 다른 패키지의 전역 에이전트가 있으면 신규 구축인데 "이전 구축 중단" 오탐 문제 해결
  - 전역 에이전트는 참고 메시지만 출력하도록 변경
- 감지 결과 테이블에 "전역 에이전트만 존재" 케이스 추가 → 신규 구축으로 처리

---

## 2026-04-28 (34차 — document-review 🟡 2건 + 🟢 1건 수정)

### 수정 — skills/project-init/SKILL.md (BE 전용 시나리오 검증)
- Step 7-C 변수 결정 테이블 뒤에 "Q2=BE이면 FE_PATTERN="" 설정, BE 섹션 주석 해제" 지침 추가 (🟡 혼동)
- Step 7-C에 BE 전용 hooks-config.sh 템플릿 별도 추가 (FE 없음 명시 포함) (🟡 혼동)
- Step 10 훅 동작 확인 진단 (b)에 BE_PATTERN 미설정 케이스 병기 (🟡 혼동)
- Step 11 완료 보고 생성 파일 목록에 `.claude/hooks-config.sh` 추가 (← git 커밋 필수 안내 포함) (🟢 개선)

---

## 2026-04-28 (33차 — README 설치 검증 패턴 보완)

### 수정 — README.md
- 설치 검증 `grep -E` 패턴에 `project-issue|project-pr|document-review` 추가 (전체 하네스 스킬 6개 모두 확인)

---

## 2026-04-28 (32차 — doc-quality-loop 🟡 2건 수정)

### 수정 — doc-quality-loop 발견 이슈 (🟡 2건)
- `공용_하네스_구축_가이드.md` — 하네스 폴더 구조 표에 `hooks/` 폴더 항목 추가 (🟡 혼동 — README와 불일치)
- `Claude Code/에이전트_정의_가이드.md` — `model:` 파일 구조 예시에 단축명 사용 가능 여부 명시 (`sonnet`으로 예시 변경 + 에이전트 MD 파일 전용 단축명 안내 괄호 추가) (🟡 혼동 — settings.json_템플릿.md 정식 ID와 혼동 우려)
- `설정_템플릿/settings.json_템플릿.md` — 모델 테이블 아래에 에이전트 MD 파일 단축명 사용 가능 여부 보충 설명 추가

---

## 2026-04-28 (31차 — 검증 전략 문서명 복원 + 품질 루프 수정 2건)

### 변경 (파일 이름)
- `운영_가이드/FE_검증_전략.md` → `운영_가이드/UI_검증_전략.md` (FE·BE 모두 없는 경우 UI·API 쌍으로 관리. 내부 제목 `UI 검증 전략`과 일치)

### 수정 (파일명 변경에 따른 참조 업데이트)
- `공용_하네스_구축_가이드.md` — 관련 문서 링크 `FE_검증_전략.md` → `UI_검증_전략.md`
- `운영_가이드/API_검증_전략.md` — 관련 문서 링크 2곳 갱신
- `Claude Code/템플릿/CLAUDE.md_템플릿.md` — STEP 2 UI 변증 참조 경로 갱신

### 수정 — doc-quality-loop 발견 이슈 (🔴·🟡 각 1건)
- `Claude Code/템플릿/CLAUDE.md_템플릿.md` — 협의 대기 처리: `HANDOFF.md §2` → `HANDOFF_NOW.md §2` (🔴 차단 — HANDOFF.md에 §2 없음)
- `운영_가이드/세션_패턴_모음.md` — 패턴 5 커밋 형식에 `docs:` 타입 접두사 추가 (🟡 혼동 — git_워크플로우_템플릿.md 기준 불일치)

---

## 2026-04-27 (30차 — HANDOFF 아카이브 기준·목적지 통일)

### 수정 — 운영_가이드/월초_아카이브_절차.md
- 아카이브 목적지: `history/HANDOFF_archive_YYYY.md` → `plans/HANDOFF_archive_YYYY.md` (HANDOFF.md 아카이브는 plans/ 하위)

### 수정 — 운영_가이드/HANDOFF_유지_규칙.md
- HANDOFF.md 아카이브 트리거: "1년치 초과 시" → "월초에 전월 Session Update 전체" (실제 운영 주기와 일치)

---

## 2026-04-27 (29차 — 세션_노트_템플릿 이관 기준 통일 + 빌드_검증_템플릿 BE 항목 추가)

### 수정 — Claude Code/템플릿/세션_노트_템플릿.md
- 이관 기준: "60일 이상" → "30일 이상" (docs_디렉토리_구조.md / CLAUDE.md와 기준 통일)

### 수정 — Claude Code/템플릿/빌드_검증_템플릿.md
- 누락 시 보완 경로 표: `BE_*.md | Step 9 | Phase 9-C` 항목 추가 (스크립트에서 이미 확인하나 표에 누락됐던 항목)

---

## 2026-04-27 (28차 — docs_디렉토리_구조 BE 문서 패턴 반영)

### 수정 — Claude Code/docs_디렉토리_구조.md
- 디렉토리 트리: `pages/<도메인>/` 하위에 `BE_<기능명>.md` 항목 추가
- 역할 테이블: `pages/` → "도메인별 기능 정리 문서 (FE: FE_*.md, BE: BE_*.md)" + 훅 감지 설명에 BE_*.md 포함
- 페이지 네이밍 규칙: BE 프로젝트 예시(auth/user/order) 신규 추가 + 파일명·훅 감지 패턴 BE 병기

---

## 2026-04-27 (27차 — 스킬 목록 노트 경로 안내 수정 + 개요.md 트러블슈팅 링크 추가)

### 수정 — Claude Code/스킬 목록.md
- 개인 스킬 노트 주석: "설치 후 필수" → install.sh --personal 자동 치환 동작 설명으로 교체. 수동 설정 필요 시 트러블슈팅.md 참조 링크 추가.

### 수정 — Claude Code/개요.md
- 관련 문서 목록에 `Claude Code/트러블슈팅.md` 항목 추가

---

## 2026-04-27 (26차 — 트러블슈팅 --project-skills 제거 + hooks-config.sh 실제 증상 반영)

### 수정 — Claude Code/트러블슈팅.md
- `install.sh --project-skills` (없는 플래그) → `bash install.sh` (프로젝트 스킬) / `bash install.sh --personal` (개인 스킬) 로 분리 안내
- `hooks-config.sh 소싱 오류` 섹션: 잘못된 bash 에러 메시지 → 실제 증상(`⚠️ [훅 미설정] ...` 플레이스홀더 경고)으로 교체

---

## 2026-04-27 (25차 — hooks-config.sh 변수명 불일치 수정 + install.sh --all 플래그 제거)

### 수정 — Claude Code/트러블슈팅.md
- `install.sh --all` → `bash install.sh` / `bash install.sh --force --personal --hooks` 로 수정 (--all 플래그 없음)
- hooks-config.sh 예시 변수명 수정: `FE_DOC_DIR`/`BE_DOC_DIR` → `FE_DOC_BASE`/`FE_DOC_DIR_BASE` 등 실제 스크립트 변수명으로 교체

### 수정 — 운영_가이드/팀_훅_설정_공유.md
- hooks-config.sh 템플릿: `FE_DOC_DIR`/`BE_DOC_DIR` → `FE_DOC_DIR_BASE`/`BE_DOC_DIR_BASE` 로 수정

### 수정 — 공용_하네스_구축_가이드.md
- BE hooks-config.sh 예시: 잘못된 `FE_DOC_DIR`/`BE_DOC_DIR` → 올바른 변수명(`BE_DOC_BASE`, `BE_DOC_DIR_BASE`) + BE 변수 전체 교체
- BE 에이전트 활용 패턴: `agent-service-dev` → `일반 작업 (또는 프로젝트 dev 에이전트)` 로 범용 표현으로 수정

### 수정 — README.md
- 폴더 구조에 `Claude Code/트러블슈팅.md` 반영

---

## 2026-04-27 (24차 — 노트 경로 자동 치환 문서화 + 트러블슈팅 가이드 신규 + BE 빠른 시작 추가)

### 수정 — README.md
- `개인 스킬에 노트 경로 연결` 섹션: install.sh 자동 치환 동작 설명 추가, sed 명령은 수동 설정 폴백으로 재배치

### 수정 — 공용_하네스_구축_가이드.md
- `개인 스킬 설치 후 — 노트 경로 플레이스홀더 교체` 블록: 자동 치환 동작 설명으로 교체, sed 명령은 건너뛴 경우 폴백으로 재배치
- `BE 프로젝트 빠른 시작` 섹션 신규 추가: FastAPI/Go Q&A 예시 + hooks-config.sh + 에이전트 패턴 포함

### 신규 — Claude Code/트러블슈팅.md
- install.sh 실행 권한·중간 실패·gh auth 오류, 훅 미동작·hooks-config.sh 소싱 오류, `/project-init` 재실행 케이스, HANDOFF 60줄 초과 처리 정리

---

## 2026-04-27 (23차 — 훅 S49 반영 + 문서 품질 7건 수정)

### 수정 — Claude Code/훅_스크립트_전문.md (S49 반영)
- `pre-commit-doc-check.sh` 코드블록을 S49 버전으로 전체 교체: 변수 선언(`FE_COMMIT_PATTERN` 등) + `.claude/hooks-config.sh` 자동 소싱 방식으로 갱신
- `check-source-doc.sh` 코드블록을 S49 버전으로 전체 교체: 변수 선언(`FE_PATTERN` 등) + `.claude/hooks-config.sh` 자동 소싱 방식으로 갱신
- "신규 프로젝트 적용 절차" 재작성: 구버전 "if 블록 직접 수정" → 변수 설정 + hooks-config.sh 팀 공유 방식으로 교체. Section 1(변수 표) · Section 2(hooks-config.sh 팀 공유) · Section 3(다중 프로젝트) · Section 4~5(권한·settings.json) 구조

### 수정 — README.md (🔴)
- 훅 설치 후 안내: "필수: [프로젝트 설정] 구간 수정" → "/project-init 자동 생성, 수동 조정 시 참조"

### 수정 — 공용_하네스_구축_가이드.md (🟡)
- Step 2 훅 설치 후 안내: "[프로젝트 설정] 구간 직접 수정" → "/project-init 자동 생성" 방식으로 변경

### 수정 — install.sh (🟡)
- 훅 완료 메시지: "각 스크립트 [프로젝트 설정] 구간 수정하세요" → "/project-init 자동 생성, 수동 조정 시 참조"

### 수정 — Claude Code/훅 설정.md (🟡)
- "스크립트 내부에서 설정" → "프로젝트 레포의 .claude/hooks-config.sh로 설정" (2곳)
- "새 프로젝트에 훅 적용 시" 섹션: 구버전 3단계 → install.sh --hooks + /project-init 자동 생성 방식으로 재작성

### 수정 — 운영_가이드/HANDOFF_유지_규칙.md (🟡)
- "2주 이상 미착수 항목 → HANDOFF.md §보류로 이관" → "⏸ 태그 추가 후 §2 하단으로 이동 (60줄 초과 시 HANDOFF.md로 이관)" (session-close·CLAUDE.md 템플릿과 일치)

### 수정 — Claude Code/초기_설정_체크리스트.md (🟡)
- Phase 10-C 훅 기대 결과: `[문서 미존재]` → `[FE 문서 미존재]` / `[BE 문서 미존재]` (실제 훅 출력과 일치)

### 수정 — skills/project-init/SKILL.md (🟢)
- Step 10 훅 진단 (b) 항목: "스크립트 구간 수정 필요" → ".claude/hooks-config.sh 생성 또는 7-C 재실행" 안내로 개선

### 수정 — CONTRIBUTING.md (🟢)
- GitHub Issues URL TODO 문구: `TODO:` 태그 → "배포 전 필수" 체크 형태로 명확화

---

## 2026-04-27 (22차 — 배포 후 시나리오 🟡 수정필요 32건 수정)

### 수정 — install.sh (S01 · S02 · S04 · S05 · S09 · S12 · S48 · S79)
- `install.sh` — 완료 배너에 `ls ~/.claude/skills/ | grep -E 'project-init|session-close'` 검증 명령 안내 추가 (S01)
- `install.sh` — 개인 스킬 노트경로 치환 루프를 하드코딩 목록에서 `find "$SKILLS_DST"/*/` 동적 탐색으로 교체 (S02)
- `install.sh` — --local 완료 시 `.gitignore`에 `.claude/` 패턴 포함 여부 실제 체크 + 경고 출력 (S04 · S48)
- `install.sh` — `--hooks` 모드 주석에 "훅은 --local과 관계없이 항상 전역 설치" 명시 (S05)
- `install.sh` — 훅 복사 완료 후 "훅은 git 내부 사용 — git 설치 필요" 안내 추가 (S09)
- `install.sh` — 스킬 mkdir 전 쓰기 권한 사전 체크 + 실패 시 chown 안내 출력 (S12)
- `install.sh` — 의존성 체크 시 claude 버전 파싱 후 1.x 미만이면 업데이트 안내 (S79)

### 수정 — skills/project-init/SKILL.md (S19 · S23 · S24 · S26)
- Step 2에 "모호한 답변 처리 규칙" 주석 추가 — 재질문 1회 후 기본값 적용 (S23)
- Step 3에 DOCS_BASE 결정 기준 표 추가 (단일앱 / 모노레포 패키지별) (S19)
- Step 6 에이전트 생성 후 파일 존재 검증 bash 블록 추가 (S24)
- Step 10 훅 동작 미출력 시 4단계 진단 체크리스트 추가 (S26)

### 수정 — skills/project-pr/SKILL.md (S33 · S34 · S73 · S80)
- Step 0에 git 레포 체크 추가 (S73)
- Step 0에 원격 upstream 없을 시 push 안내 추가 (S33)
- Step 0 gh auth 오류를 미인증/토큰만료로 분기 — `gh auth refresh` 안내 (S80)
- Step 2에 base 브랜치 사용자 확인 단계 추가 (S34)

### 수정 — skills/project-fix/SKILL.md (S30 · S73 · S80)
- Step 0에 git 레포 체크 + gh auth 토큰만료 분기 추가 (S73 · S80)
- Step 4에 QA 브랜치(`task/` · `fix/`) 감지 — 현재 브랜치 유지 분기 추가 (S30)

### 수정 — skills/project-issue/SKILL.md (S73 · S80)
- Step 0에 git 레포 체크 + gh auth 토큰만료 분기 추가 (S73 · S80)

### 수정 — hooks/pre-commit-doc-check.sh (S74 · S75)
- develop·main·master 브랜치 직접 커밋 시 경고 출력 (exit 2, 비차단) (S75)
- 커밋 메시지에 이슈 번호(`#N`) 없으면 경고 출력 (exit 2, 비차단) (S74)

### 수정 — Claude Code/초기_설정_체크리스트.md (S18 · S21 · S24)
- Phase 1-B: 폴더 100개 초과 시 Explore 서브에이전트 권장 안내 추가 (S21)
- Phase 7-C: FE `if` 블록을 먼저, BE `elif` 블록을 그 다음 — 순서 중요성 명시 (S18)
- Phase 6-D: 에이전트 파일 존재 검증 단계 신규 추가 (S24)

### 수정 — skills/session-close/SKILL.md (S67)
- HANDOFF_NOW.md §2 갱신 시 14일 초과 항목 ⏸ 태그 처리 규칙 추가 (S67)

### 수정 — README.md (S50 · S51 · S56)
- 지원 플랫폼 표에 "macOS · Linux 검증됨" 명시 (S50)
- 업그레이드 섹션에 개별 스킬 수동 삭제 후 재설치 방법 추가 (S51)
- 업그레이드 섹션에 Claude Code 버전 업 후 호환성 확인 절차 추가 (S56)

### 추가 — 운영_가이드/월초_아카이브_절차.md (S68)
- 월초 HANDOFF.md 전월 Session Update 아카이브 절차 + bash 스크립트 신규 작성

### 갱신 — 시나리오 파일 (80개 전량)
- 🔴 9건 + 🟡 32건 모두 ✅ 완료로 상태 갱신
- INDEX.md 현황 요약: ✅75 / 🟢5 / 🔴0 / 🟡0

---

## 2026-04-27 (21차 — 배포 후 시나리오 🔴 미비 9건 수정)

### 수정 — install.sh (S08 · S11 · S52 · S53 · S76)
- `install.sh` — 의존성 체크를 필수(claude·git)와 선택(python3)으로 분리. python3 없으면 settings.json 단계만 건너뛰고 스킬·훅 설치는 계속 진행 (S08)
- `install.sh` — settings.json JSON 파싱 실패 시 `.bak` 백업 후 진행하도록 수정. 3개 Python 병합 블록 모두 `shutil.copy2` 백업 로직 추가 (S11)
- `install.sh` — `--force` 플래그 추가. 기존 스킬·훅을 덮어쓰며 업그레이드. `--force` 없으면 기존 동작 유지 (S53)
- `install.sh` — 훅 스킵 시에도 `chmod +x` 실행해 실행 권한 보장 (S76)
- `install.sh` — 배너에 `하네스 버전: X.Y.Z` 출력. `HARNESS_VERSION=$(cat "$HARNESS_DIR/VERSION")` (S52)

### 추가 (S52)
- `VERSION` — 하네스 버전 파일 신규 생성 (`1.0.0`)

### 수정 — README.md (S53)
- `README.md` — "업그레이드" 섹션 추가: `--force` 플래그 사용법 및 `cat 하네스/VERSION` 버전 확인 명령

### 수정 — project-init/SKILL.md (S22 · S71)
- `skills/project-init/SKILL.md` — Step 4 기존 CLAUDE.md 처리 옵션 표 추가: 병합·대체·건너뜀 선택지와 추천 상황 명시. "선택 전까지 파일 수정 금지" 명시 (S22)
- `skills/project-init/SKILL.md` — Step 0에 재실행 감지 블록 추가: 기존 파일 존재 여부 bash 체크 → 부분 존재 시 사용자에게 A/B/C 재개 지점 선택 요청 (S71)
- `skills/project-init/SKILL.md` — Step 6 다중 패키지 모노레포 에이전트 분리 기준 표 추가 (S20)

### 수정 — 초기_설정_체크리스트.md (S20)
- `Claude Code/초기_설정_체크리스트.md` — Phase 1-B에 다중 패키지 모노레포 에이전트 분리 기준 표 추가
- `Claude Code/초기_설정_체크리스트.md` — Phase 6-A에 패키지 수·스택 동질성 기준 에이전트 구성 표 추가

### 추가 (S49)
- `운영_가이드/팀_훅_설정_공유.md` — 신규 작성. `.claude/hooks-config.sh` 공유 파일로 팀 훅 경로 설정 일원화하는 방법·온보딩 절차·주의사항 기술

---

## 2026-04-27 (20차 — FE·BE 시나리오 검증 10건 수정)

### 수정 (🔴 차단 2건)
- `skills/project-init/SKILL.md` Step 10 — 훅 동작 확인 메시지 구버전(`[FE 문서 미존재]`/`[FE 문서 확인]`) → `[문서 미존재]`/`[문서 확인]`으로 FE·BE 공용 메시지로 교체
- `skills/project-init/SKILL.md` Step 9 — BE 첫 기능 정리 문서(`BE_*.md`) 작성 안내 섹션 추가. 핵심 API 도메인 1개 선택 → `BE_기능정리_템플릿.md` 기반 신규 작성 안내

### 수정 (🟡 혼동 6건)
- `skills/project-init/SKILL.md` Step 7 — 훅 설치 절차 누락 보완. 7-A(additionalDirectories 설정) → 7-B(install.sh --hooks 실행) → 7-C(경로 패턴 설정) 3단계 절차로 재편
- `skills/project-init/SKILL.md` Q8 — "Q2=BE이면 이 질문을 건너뛴다" 명시 추가 (BE 전용 프로젝트에서 Playwright 질문 노출 방지)
- `Claude Code/초기_설정_체크리스트.md` Phase 5-C — BE conventions 기준 추가. 린터(ruff/black/golangci-lint), pytest fixture 패턴, alembic/golang-migrate 마이그레이션 도구, OpenAPI 스펙 위치 항목 신설
- `hooks/pre-commit-doc-check.sh` + `Claude Code/훅_스크립트_전문.md` — BE DOMAIN 추출 sed 패턴에 `models/`, `schemas/` 경로 추가
- `skills/session-close/SKILL.md` Step 3-A — FE·BE 기능 정리 문서 갱신 여부 확인 단계를 HANDOFF 갱신 전에 수행하도록 선행 체크 추가
- `Claude Code/템플릿/BE_기능정리_템플릿.md` — 에이전트 사용 안내에 `API_검증_전략.md` 3단계 검증 절차 참조 추가

### 수정 (🟢 개선 2건)
- `Claude Code/템플릿/빌드_검증_템플릿.md` — BE 수동 확인 항목 프레임워크 자동 감지(pyproject.toml/go.mod/package.json) 후 Python·Go·Node 각 명령어 분기 출력으로 개선
- `운영_가이드/세션_패턴_모음.md` — 패턴 8(DB 마이그레이션), 패턴 9(API 엔드포인트) [검증] 단계에 "※ 3단계 순서 준수 (API_검증_전략.md 참조)" 안내 추가

### 추가
- `TODO_시나리오_개선.md` — 10건 개선 항목 체크리스트 문서 신규 생성 (전량 완료)

---

## 2026-04-27 (19차 — BE 스크립트·문서 형식 일치)

### 수정
- `hooks/pre-commit-doc-check.sh` — FE 전용 구버전(`SOURCE_FILES` 단일 루프)을 `훅_스크립트_전문.md` 정식 버전으로 교체. `FE_FILES`+`BE_FILES` 분리, for 루프 2개(FE·BE), `DOC_PREFIX` 동적 적용으로 `BE_*.md` 실제 감지 가능
- `hooks/check-source-doc.sh` — `[프로젝트 설정]` 주석 구역을 `훅_스크립트_전문.md`와 동기화. FE·BE 패턴 구분 설명 + `DOC_PREFIX` 명시 추가
- `Claude Code/훅_스크립트_전문.md` — "신규 프로젝트 적용 절차": `pre-commit-doc-check.sh 수정 항목` 표에 `BE_FILES` grep 패턴·BE DOMAIN 추출·BE DOC_DIR 항목 추가. elif 예시를 FE→BE 추가 패턴으로 교체 (실질적 사용 시나리오 반영)
- `Claude Code/초기_설정_체크리스트.md` — Phase 7-C 설명에 FE/BE 구분 안내 추가. `check-source-doc.sh` FE `if` 블록·BE `elif` 블록 교체 방법 및 `pre-commit-doc-check.sh` `FE_FILES`·`BE_FILES` 패턴 분리 설정 방법 명시

---

## 2026-04-27 (18차 — 파일명 범용화)

### 변경 (파일 이름)
- `hooks/check-fe-doc.sh` → `hooks/check-source-doc.sh` (FE·BE 양쪽 커버하는 범용 이름으로 변경)
- `운영_가이드/UI_검증_전략.md` → `운영_가이드/FE_검증_전략.md` (대칭 명명: `API_검증_전략.md`와 짝)

### 수정 (파일명 변경에 따른 참조 업데이트)
- `hooks/pre-commit-doc-check.sh` — 파일 상단 주석 "FE 개발문서" → "개발문서 (FE·BE)" / 경고 메시지 동일 갱신
- `install.sh` — `check-fe-doc.sh` → `check-source-doc.sh` (복사 명령·settings.json 등록 코드·안내 메시지 전체)
- `설정_템플릿/settings.json_템플릿.md` — command 값·훅 요약 표·python3 병합 스크립트 내 참조
- `Claude Code/훅 설정.md` — 섹션 헤더·목적 설명·훅 파일 트리를 FE→FE·BE 범용으로 수정
- `Claude Code/훅_스크립트_전문.md` — 섹션 헤더·스크립트 내 미설정 경고 문구·수정 항목 표·elif 예시·chmod·settings.json JSON 예시
- `Claude Code/초기_설정_체크리스트.md` — Phase 7 안내 문구·7-B 설치 파일명·7-C 수정 대상·10-C 기대 결과 메시지
- `CONTRIBUTING.md` — 로컬→하네스 동기화 cp 명령
- `skills/project-init/SKILL.md` — Step 7·Step 10 참조
- `운영_가이드/API_검증_전략.md` — 관련 문서 링크 `UI_검증_전략.md` → `FE_검증_전략.md`

---

## 2026-04-27 (17차 — BE·풀스택 범용화)

### 추가
- `Claude Code/템플릿/BE_기능정리_템플릿.md` — 신규 생성. API 엔드포인트·요청응답 스펙·비즈니스 로직·DB 마이그레이션 이력·의존 서비스 문서화 템플릿
- `운영_가이드/API_검증_전략.md` — 신규 생성. BE·풀스택용 3단계 검증 전략 (단위→통합→실서버). DB 마이그레이션 rollback 테스트 포함

### 수정
- `hooks/check-fe-doc.sh` — `DOC_PREFIX` 변수 도입. BE 소스 패턴 elif 예시 추가. FE_*.md / BE_*.md 동적 감지로 확장
- `Claude Code/훅_스크립트_전문.md` — pre-commit-doc-check.sh BE 파일 확장자(`.py/.go/.java/.kt/.rs`) 지원 추가. FE/BE 파일 분리 처리 구조로 개선. check-fe-doc.sh BE 패턴 주석 추가
- `Claude Code/템플릿/agent_문서_템플릿.md` — 분석 전 필수 확인 목록에 BE 항목 추가 (DB/ORM/인증/테스트 구조). architecture.md FILL 주석에 FastAPI·Go 기반 BE 작성 예시 추가
- `Claude Code/템플릿/빌드_검증_템플릿.md` — `PROJECT_TYPE != FE` 조건부 블록 추가. BE_*.md 문서 수·마이그레이션 디렉토리·테스트 디렉토리 자동 확인. 수동 확인 항목 안내 추가
- `운영_가이드/세션_패턴_모음.md` — 패턴 8(DB 마이그레이션 작업)·패턴 9(API 엔드포인트 추가) 추가

---

## 2026-04-27 (16차 — 실패 시나리오 2차 강화)

### 수정
- `skills/project-pr/SKILL.md` — Step 0에 현재 브랜치 = base 브랜치 감지 분기 추가 (develop에서 직접 PR 시도 차단)
- `skills/project-fix/SKILL.md` — addSubIssue GraphQL 실패 시 수동 연결 안내 + 브랜치 생성 계속 진행하도록 명시
- `skills/project-init/SKILL.md` — Step 4 상단에 하네스 절대경로 확인 블록 추가, 이후 모든 `하네스/Claude Code/` 경로를 `<하네스경로>/Claude Code/`로 통일
- `README.md` — 노트 시스템 섹션에 개인 스킬 플레이스홀더 교체 여부 확인 명령 추가

---

## 2026-04-27 (15차 — 실패 시나리오 대응 강화)

### 추가
- `hooks/check-fe-doc.sh` — `<소스경로>` 플레이스홀더 미교체 시 `exit 2` 경고 추가 (조용한 실패 방지)
- `hooks/pre-commit-doc-check.sh` — `<소스경로>` 플레이스홀더 미교체 시 `exit 2` 경고 추가
- `skills/project-fix/SKILL.md` — Step 0 추가: `gh auth status` 인증 선행 확인
- `skills/project-pr/SKILL.md` — Step 0 추가: `gh auth status` 인증 확인 + 브랜치 기존 PR 중복 체크
- `skills/project-issue/SKILL.md` — Step 0 추가: `gh auth status` 인증 선행 확인
- `skills/project-init/SKILL.md` — Step 1 bash 최상단에 `git rev-parse --git-dir` 저장소 감지 분기 추가
- `skills/session-close/SKILL.md` — HANDOFF_NOW.md 갱신 후 `wc -l` 60줄 초과 자동 경고 추가

---

## 2026-04-27 (14차 — 배포 상용화 기준 보완)

### 수정
- `skills/project-issue/SKILL.md` — Step 4 addSubIssue node ID 추출 단계 추가 (`PARENT_ID`/`CHILD_ID` 변수, `--json id`)
- `install.sh` — 의존성 실패 시 claude·python3·git 설치 명령 안내 추가
- `install.sh` — `--hooks` 완료 메시지에 훅 동작 확인 방법 추가 (조용한 실패 방지)
- `install.sh` — 전역 설치 완료 메시지 다음 단계에 `gh auth login` 안내 추가
- `README.md` — 노트 시스템 섹션에 "개인 스킬 미사용 시 건너뛰어도 됨" 안내 추가
- `CONTRIBUTING.md` — GitHub Issues URL TODO 주석 추가 (배포 전 교체 필요 명시)
- `.gitignore` — 신규 생성 (`.DS_Store`, `*.skill`, `__pycache__/`, `_수정_체크리스트.md`)
- 전체 `.md` 파일 frontmatter `updated` 날짜 2026-04-23/24 → 2026-04-27 일괄 갱신 (23개)

---

## 2026-04-27 (13차 — 시나리오 재검증 후 수정)

### 수정
- `install.sh` — 단계 표기 `[1/4]~[4/4]` → `[1/5]~[5/5]` 통일
- `README.md` — frontmatter `updated: 2026-04-27` → `2026-04-27`
- `공용_하네스_구축_가이드.md` — 방법 B git clone 폴더명 `~/dev-harness` → `하네스` (실행 명령과 일치)
- `skills/project-fix/SKILL.md` — Step 3 node ID 추출 단계 추가: `PARENT_ID`/`CHILD_ID` 변수 및 `--json id` 필드 명시

---

## 2026-04-27 (12차 — 상품성 검수 문서 리뷰)

### 수정
- `공용_하네스_구축_가이드.md` — Step 1 `<하네스-레포-URL>` 플레이스홀더 → TODO 주석으로 명시 (배포 전 교체 필요 안내)
- `공용_하네스_구축_가이드.md` — Step 2에 `--hooks` 플래그 옵션 추가 (README와 불일치 해소)
- `README.md` — "스킬 업데이트" 섹션 제거 (CONTRIBUTING.md 중복 내용, 기여자용 분리)
- `Claude Code/스킬 목록.md` — 상단에 "번들 포함 여부" 안내 추가 (비번들 스킬과 혼재 혼란 해소)
- `personal-skills/*/SKILL.md` 6개 — 상단에 `<개인_노트_경로>` 플레이스홀더 경고 주석 추가
- `운영_가이드/시나리오_검증.md` — 상단에 "📌 내부 문서" 표시 추가
- `프롬프트/서브에이전트_호출_패턴.md` — 상단에 "📌 내부 문서" 표시 추가
- `운영_가이드/HANDOFF_유지_규칙.md` — `updated` 날짜 2026-04-23 → 2026-04-27
- `Claude Code/훅 설정.md` — `updated` 날짜 2026-04-23 → 2026-04-27
- `Claude Code/스킬 목록.md` — `updated` 날짜 2026-04-23 → 2026-04-27

---

## 2026-04-24 (11차 — 미반영 항목 수정 + updated 날짜 일관성)

### 수정
- `skills/session-close/SKILL.md` — Step 3-A ① §1 "이번 세션 완료 (YYYY-MM-DD)" 필드 갱신 안내 추가 (10차에 기록됐으나 실제 파일 미반영)
- `Claude Code/초기_설정_체크리스트.md` — `updated: 2026-04-27` → `2026-04-24` (9차 기록 후 미반영)
- `Claude Code/개요.md` — `updated: 2026-04-27` → `2026-04-24` (10차 변경 반영)
- `Claude Code/docs_디렉토리_구조.md` — `updated: 2026-04-27` → `2026-04-24` (9차 변경 반영)
- `Claude Code/템플릿/HANDOFF_NOW_템플릿.md` — `updated: 2026-04-27` → `2026-04-24`
- `운영_가이드/세션_패턴_모음.md` — `updated: 2026-04-27` → `2026-04-24` (10차 변경 반영)

---

## 2026-04-24 (10차 — 시나리오 검증 후 수정)

### 수정
- `skills/project-fix/SKILL.md`
  - Step 3 `--body` 문자열의 `\n`이 실제 줄바꿈으로 해석되지 않는 문제 → heredoc으로 교체
  - Step 3 `--label "bug"` 하드코딩 → `gh label list`로 존재 여부 확인 후 조건부 추가로 변경 (레이블 없으면 실패 방지)
- `Claude Code/초기_설정_체크리스트.md` — "에이전트 사용 방법" 예시: "Dev-Vault의 초기_설정_체크리스트" → 실제 경로 `하네스/Claude Code/초기_설정_체크리스트.md`로 수정; "Phase 1부터" → "Phase 0부터"
- `Claude Code/개요.md`
  - 관련 문서 Obsidian 링크 전량 → 실제 경로로 교체
  - "Phase 1~10" → "Phase 0~10"
- `skills/session-close/SKILL.md` — Step 3-A ① §1 갱신 안내에 "이번 세션 완료 (YYYY-MM-DD)" 필드 갱신 안내 추가 (HANDOFF_NOW 템플릿 필드 누락 방지)
- `운영_가이드/세션_패턴_모음.md` — 패턴 2 [검증] 단계에 "(FE 프로젝트) 수정된 도메인 FE_*.md 갱신 여부 확인" 추가

---

## 2026-04-24 (9차 — Obsidian 문서 품질 수정)

### 수정
- `Claude Code/템플릿/CLAUDE.md_템플릿.md` — `updated: 2026-04-27` → `2026-04-24` (4차 이후 갱신 누락)
- `Claude Code/에이전트_정의_가이드.md` — `updated: 2026-04-27` → `2026-04-24` (4차 이후 갱신 누락)
- `운영_가이드/세션_패턴_모음.md` — 패턴 7 "Phase 1~10" → "Phase 0~10" (Phase 0 스킬 설치 확인 추가 후 미반영)
- `Claude Code/docs_디렉토리_구조.md` — `git-workflow/` 【선택】 → 【필수】로 변경 (SKILL.md mkdir·빌드_검증_템플릿 check_file과 일관성 확보); 필수 디렉토리 테이블에 `git-workflow/` 행 추가, 선택 테이블에서 제거
- `공용_하네스_구축_가이드.md` — Step 4 검증 방법 갱신: 명시적 요청 "HANDOFF_NOW.md 읽고 요약해줘" → 자연스러운 작업 시작 메시지로 변경 (CLAUDE.md STEP 0-B 자동 출력 반영)
- `README.md` — YAML 프론트매터(`tags`, `updated`) 추가 (다른 모든 Obsidian 문서와 통일)

---

## 2026-04-24 (8차 — 시나리오 검증 후 잔여 이슈 수정)

### 수정
- `Claude Code/템플릿/CLAUDE.md_템플릿.md` — STEP 0-B: HANDOFF_NOW.md 읽은 후 §1·§2를 사용자에게 요약 출력하는 지시 추가
- `Claude Code/에이전트_정의_가이드.md` — dev 에이전트 "작업 규칙"에 "규칙 위반 발견 시: 즉시 중단 → 위반 내용 보고 → 지시 후 재개. 임의 수정 후 진행 금지" 추가

---

## 2026-04-24 (7차 — 하네스 산출물 강제성 강화)

### 수정
- `Claude Code/템플릿/CLAUDE.md_템플릿.md`
  - **0-D**: "구현 계획 수립" → "구현 계획 수립 및 확인"으로 변경. 계획 제시 포맷 추가 + "사용자 확인 전까지 코드 작성·파일 수정 금지" 명시
  - **STEP 1**: 규칙 테이블 앞에 "규칙 위반 발견 시: 즉시 중단 → 사용자 보고 → 지시 후 재개. 임의 수정 후 진행 금지" callout 추가. "위반 시" 컬럼을 "즉시 중단 → 사용자 보고 → 지시 후 재개" 패턴으로 통일
  - **STEP 2**: "체크 실패 시: 사용자에게 보고한 뒤 수정 방향 확인. 스스로 판단해 수정 후 완료 처리 금지" 추가
  - **"작업 범위 초과 시" 섹션 신설**: 요청 범위 밖 변경 발생 시 즉시 중단 → 보고 → 허가 후 진행 절차 명시
- `Claude Code/에이전트_정의_가이드.md`
  - **dev 에이전트 템플릿 "작업 전 필수"**: 3번 항목 추가 — "구현 계획 수립 후 사용자에게 제시, 확인 전 코드 작성 금지"
  - **dev 에이전트 템플릿 "작업 규칙"**: "요청 범위 밖 변경 시: 즉시 중단 → 사용자 보고 → 허가 후 진행" 추가

---

## 2026-04-24 (6차 — 검증 시나리오 실행 후 수정)

### 수정
- `Claude Code/초기_설정_체크리스트.md` — Phase 3-A bash 주석 Q번호 오류: "모노레포: Q6 답변에 따라" → "Q7 답변에 따라" (체크리스트 Q6 = 이슈 트래커, Q7 = 모노레포 docs 위치)
- `Claude Code/템플릿/빌드_검증_템플릿.md` — 스크립트 전면 재작성: `.clone/agents/` 오타 수정 → `.claude/agents/`, `PROJECT_TYPE` 변수 추가, `warn_file()` 함수 분리(BE 프로젝트 FAIL 카운트 오류 제거), 조건부 섹션을 `if [ "$PROJECT_TYPE" != "BE" ]`로 래핑, 미사용 `check_dir()` 제거, 최종 메시지 "필수 항목 전량 통과"로 통일

---

## 2026-04-24 (5차 — 빌드 검증 템플릿 + 스킬 목록 누락 수정)

### 추가
- `Claude Code/템플릿/빌드_검증_템플릿.md` 신규 생성: bash 검증 스크립트(필수·에이전트·스킬·조건부 항목 전체 체크) + 누락 시 보완 경로 표

### 수정
- `skills/project-init/SKILL.md` — Step 10 앞에 빌드 검증 블록 추가(Read 명령형). Step 4 포함 항목 스킬 목록 `/project-issue`·`/document-review` 누락 → bash 확인 명령 + 전체 스킬 표로 교체
- `Claude Code/초기_설정_체크리스트.md` — Phase 4에 4-C(스킬 목록 기재) 신설, 기존 4-C → 4-D. Phase 10에 10-A(빌드 결과 파일 검증) 신설, 기존 10-A/B/C → 10-B/C/D. 참조 문서 인덱스 Phase 10 갱신.
- `Claude Code/템플릿/CLAUDE.md_템플릿.md` — 스킬 섹션 플레이스홀더 → bash 확인 명령 + 기본 5개 스킬 표로 교체

---

## 2026-04-24 (4차 — 프로젝트 로컬 스킬 설치 기능 추가)

### 추가
- `install.sh` — `--local` 플래그 추가: `~/.claude/skills/` 대신 `.claude/skills/`(프로젝트 로컬)에 스킬 설치. `.claude/settings.json`에 harness 경로 등록. git 추적 시 팀 전체 공유 가능.
- `skills/project-init/SKILL.md` — Step 0(환경 확인) 추가: 전역·로컬 스킬 설치 여부 확인 bash 블록 + 전역/로컬 설치 옵션 안내. Step 11 조건부 파일(design-system.md, FE_*.md) 추가.
- `Claude Code/초기_설정_체크리스트.md` — Phase 0(스킬 설치 확인) 추가: 0-A 설치 여부 확인 bash / 0-B 전역·로컬 설치 방법 선택 안내.

---

## 2026-04-24 (3차 — 시나리오 검증 후 수정)

### 수정 (Step 10/Phase 10 일관성)
- `skills/project-init/SKILL.md` — Step 10에 훅 동작 확인 블록 추가 (체크리스트 Phase 10-B와 정렬)
- `Claude Code/초기_설정_체크리스트.md` — 참조 문서 인덱스 Phase 10 중복 행 삭제 (`git_워크플로우_템플릿.md`는 Phase 9에 이미 등록)

---

## 2026-04-24 (2차 개선 — 템플릿 Read 강제화 + Obsidian 링크 제거)

### 수정 (에이전트 실행 문서 품질 개선)
- `skills/project-init/SKILL.md` — Step 4·5·6·9 템플릿 참조를 "Read로 먼저 읽어라" 명령형으로 전환; Obsidian 링크 3개 (`[[초기_설정_체크리스트]]`, `[[docs_디렉토리_구조]]`, `[[하네스/...]]`) → 실제 경로; Step 4 포함 항목에 서브에이전트 호출 규칙·팀 프로세스·등록 스킬 추가; Step 7 훅 스크립트·훅 설정 파일 참조를 Read 명령형으로 전환; Step 9 HANDOFF_NOW 인라인 템플릿을 테이블 형식으로 교정
- `Claude Code/초기_설정_체크리스트.md` — Phase 4·5·6·7·8·9·10 Obsidian 링크 전량 실제 경로로 교체; Phase 5-B `Q2(FE/BE/풀스택)` → `Phase 1-B 분석 결과(FE/BE/풀스택)` (Q번호 오류 수정); Phase 6 `Q2·Q3` → `Phase 1-B FE/BE/풀스택 판단 + Q3 에이전트 위치` (Q번호 오류 수정); git-workflow/branch-commit.md 작성 단계를 Phase 10-C → Phase 9-B로 이동 (SKILL.md Step 9와 정렬); Phase 9 제목 갱신; Phase 10 제목 "검증 및 마무리"로 수정
- `Claude Code/훅_스크립트_전문.md` — 훅 heredoc 메시지 내 `[[템플릿/FE_기능정리_템플릿]]` → 실제 경로

---

## 2026-04-24 (1차)

### 수정 (교차 참조 불일치)
- `공용_하네스_구축_가이드.md` — Step 3 Q&A 설명을 실제 SKILL.md Q 목록에 맞게 교정 (4개→최대 8개, 항목명 수정), Q&A 팁 Q번호 Q3/Q4→Q5/Q6, 수동 구축 Phase 4 mkdir에 agent·pages·git-workflow 추가, HANDOFF 경로에 서비스명 삽입
- `Claude Code/초기_설정_체크리스트.md` — Phase 5-B architecture.md 기재 항목에 BE·풀스택 분기 추가, Phase 5-D·9-B "(FE 프로젝트)"→"(FE·풀스택 프로젝트)"
- `Claude Code/docs_디렉토리_구조.md` — 초기 구축 명령 mkdir에 git-workflow 추가, touch 목록 pages/README.md→git-workflow/branch-commit.md 교체, design-system.md 주석 "(FE→FE·풀스택)"
- `운영_가이드/세션_패턴_모음.md` — 패턴 7 "7개 질문 수집"→"Q&A 수집 (Phase 2 참조)"
- `Claude Code/에이전트_정의_가이드.md` — 결정 흐름도 "FE→FE·풀스택", "BE/풀스택→BE 전용" 분리

---

## 2026-04-23

### 추가
- `운영_가이드/UI_검증_전략.md` — Playwright MCP 토큰 최적화 3단계 전략 (Jest → Headless → MCP)
- `personal-skills/` 폴더 신설 — daily-note, standup, meeting-note, til, weekly-retro, weekly-meeting-update 이동
- `운영_가이드/시나리오_검증.md` — 4케이스 예상시나리오 검증 결과 문서

### 변경
- `skills/project-init/SKILL.md` — Step 6개 → 11개로 전면 재작성
  - Step 1: 기존 하네스 구조 확인 bash 명령 추가, 파악 항목 9개로 확장
  - Step 2: Q4개 → Q8개로 확장 (브랜치전략 Q5, 외부경로 Q6 힌트 상세화)
  - Step 3: 단일앱/모노레포 분기 조건 명시, 기존 docs/ 구조 공존 처리 안내 추가
  - Step 4: 기존 CLAUDE.md 존재 시 병합/대체 분기 추가, Q2(FE/BE) 반영 명시, 템플릿 실제 경로 병기
  - Step 5: agent/README.md 작성 가이드 추가 (Step 6 후 목록 업데이트 안내 포함)
  - Step 6: 기존 에이전트 파일 존재 시 처리 안내 추가, 가이드 실제 경로 병기
  - Step 9: git-workflow/branch-commit.md 작성 템플릿 추가, FE_*.md 안내 추가, HANDOFF_NOW.md 기존 파일 분기 추가
  - Step 11: 완료 보고 파일 목록에 agent/README.md·branch-commit.md 추가
- `Claude Code/초기_설정_체크리스트.md` — 헤더 역할 재정의 ("/project-init 스킬의 상세 구현 기준"), Phase 5에 5-A(agent/README.md) 추가
- `Claude Code/스킬 목록.md` — "하네스 번들 스킬"을 "프로젝트 워크플로(항상 설치)"·"개인 생산성(선택 설치)"으로 분리
- `README.md` — Step 0(CLI 설치) 추가, gh auth login 안내, Obsidian 설치 가이드·노트 경로 연결 스크립트 추가, 이중 구축 경로 제거
- `공용_하네스_구축_가이드.md` — Step 0 추가 및 단계 번호 재정렬, install.sh 경로 통일, 검증 예시 출력 추가, 수동 구축 섹션 조건 명시
- `install.sh` — `[3/4]` 개인 생산성 스킬 선택 설치 단계 추가, `--personal` 플래그 지원

### 수정 (버그성)
- `skills/weekly-meeting-update/SKILL.md` — 존재하지 않는 `references/output-format.md` 참조 제거, 출력 형식 인라인 삽입

---
