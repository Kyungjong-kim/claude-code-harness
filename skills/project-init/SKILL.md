---
name: project-init
description: |
  새 프로젝트에 Claude Code 하네스를 초기화한다.
  코드베이스 파악 → Q&A → CLAUDE.md · 에이전트 · HANDOFF 전체 구축까지 원스톱.
  어느 회사·프로젝트에서나 사용 가능.
  트리거 키워드: "하네스 구축", "프로젝트 초기화", "CLAUDE.md 만들어줘", "/project-init"
---

# Project Init

새 프로젝트에 Claude Code 하네스를 처음 설치한다.
상세 구현 기준: `<하네스경로>/Claude Code/초기_설정_체크리스트.md`

---

## Step 0 — 환경 확인 (첫 실행 시)

하네스 스킬이 이 환경에 설치돼 있는지 확인한다. **이미 설치된 환경이면 Step 1로 바로 진행한다.**

```bash
# 하네스 스킬 설치 여부 확인 (전역 + 로컬)
HARNESS_SKILLS=(project-init project-fix project-issue project-pr session-close document-review)
MISSING=()
for skill in "${HARNESS_SKILLS[@]}"; do
  if [ ! -d "$HOME/.claude/skills/$skill" ] && [ ! -d ".claude/skills/$skill" ]; then
    MISSING+=("$skill")
  fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "⚠ 미설치 스킬: ${MISSING[*]}"
  echo ""
  echo "설치 옵션:"
  echo "  A) 전역 설치 (권장): bash 하네스/install.sh"
  echo "  B) 로컬 설치 (팀 공유용): bash 하네스/install.sh --local"
else
  echo "✓ 하네스 스킬 모두 설치됨"
fi
```

미설치 스킬이 있으면 사용자에게 선택을 요청한다:

| 설치 방법 | 명령 | 적용 범위 |
|-----------|------|-----------|
| **전역 설치** (권장) | `bash 하네스/install.sh` | 이 기기의 모든 프로젝트 |
| **로컬 설치** | `bash 하네스/install.sh --local` | 이 프로젝트만. `.claude/skills/`에 생성. git 추적 시 팀 전체 공유 가능 |

> **로컬 설치 선택 시**: `.claude/skills/`를 git 추적하면 팀원이 `install.sh` 없이 `git clone` 후 바로 스킬을 사용할 수 있다.

설치 완료 확인 후 Step 1로 진행한다.

### 재실행 감지 (중간 취소 후 재시작인 경우)

Step 1 진입 전에 이전 실행 흔적이 있는지 확인한다.

```bash
PARTIAL=""
[ -f CLAUDE.md ] && PARTIAL="${PARTIAL}CLAUDE.md "
[ -d docs ] && find docs -maxdepth 4 -name "HANDOFF_NOW.md" 2>/dev/null | grep -q . && PARTIAL="${PARTIAL}docs/HANDOFF_NOW.md "
[ -d .claude/agents ] && ls .claude/agents/*.md 2>/dev/null | head -1 && PARTIAL="${PARTIAL}에이전트파일(로컬) "
echo "감지: ${PARTIAL:-없음}"

# 전역 에이전트는 다른 패키지의 것일 수 있으므로 PARTIAL 판정에서 제외 — 참고 표시만
[ -d "$HOME/.claude/agents" ] && ls "$HOME/.claude/agents"/*.md 2>/dev/null | head -1 \
  && echo "참고: 전역 에이전트 폴더에 기존 파일 있음 (다른 패키지 것일 수 있음 — 이 패키지 신규 구축에 영향 없음)"
```

| 감지 결과 | 처리 |
|-----------|------|
| 아무것도 없음 | 신규 구축 — Step 1로 진행 |
| 전역 에이전트만 존재 (CLAUDE.md·로컬 에이전트·docs 없음) | 신규 구축 — 다른 패키지 에이전트로 간주, Step 1로 진행 |
| 일부 파일 존재 (CLAUDE.md 또는 로컬 에이전트 또는 docs 중 일부) | 사용자에게 재개 지점 선택 요청 (아래) |
| CLAUDE.md + docs + 에이전트(로컬) 모두 존재 | 이미 완료된 구축 — Step 10 빌드 검증만 실행 |

**부분 존재 시 사용자에게 질문:**
> "이전 구축이 중간에 중단된 것 같습니다.
> 어느 단계부터 재개할까요?
> - A) 처음부터 다시 (기존 파일 덮어쓰기)
> - B) 이미 완료된 단계 건너뛰고 미완성 단계부터
> - C) 취소"

B 선택 시: 존재하는 파일 목록을 기반으로 완료된 Step을 추론하고 다음 미완성 Step으로 이동한다.

---

## Step 1 — 코드베이스 파악 (사용자 개입 없음)

> **실행 디렉터리**: 구축 대상 프로젝트 루트에서 실행한다.
> 모노레포 안의 패키지를 구축하는 경우(예: `<패키지명>/`) 패키지 루트로 이동 후 실행한다.
> 루트 모노레포 + 패키지별 서브 모노레포 구조이면 구축 대상 패키지 루트에서 실행.
> ```bash
> pwd   # 현재 디렉터리 확인
> ls CLAUDE.md package.json 2>/dev/null   # 대상 패키지 루트인지 검증
> ```

```bash
# git 저장소 여부 확인 (git repo 아니면 경고)
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "⚠ 현재 디렉터리가 git 저장소가 아닙니다."
  echo "  하네스 구축 대상은 git 저장소여야 합니다."
  echo "  - 기존 저장소: 프로젝트 루트로 이동 후 다시 실행"
  echo "  - 신규 저장소: git init 후 다시 실행"
  # 계속할지 사용자에게 확인 요청
fi

# 기존 하네스 구조 확인 (먼저 실행)
ls CLAUDE.md .claude/ docs/ 2>/dev/null && echo "기존 하네스 존재" || echo "신규 구축"
[ -f CLAUDE.md ] && echo "--- 기존 CLAUDE.md ---" && cat CLAUDE.md
[ -d docs ] && find docs -maxdepth 3 -name "*.md" | sort
[ -d .claude/agents ] && ls .claude/agents/ 2>/dev/null

# 프로젝트 구조 파악
find . -maxdepth 4 -type d \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -not -path "*/dist/*" -not -path "*/.next/*" | sort

# 패키지·설정 파일 확인
ls package.json pyproject.toml Cargo.toml go.mod 2>/dev/null
cat package.json 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
print('name:', d.get('name'))
print('workspaces:', d.get('workspaces'))
print('scripts:', list(d.get('scripts',{}).keys()))
" 2>/dev/null

# git 정보 확인
git remote get-url origin 2>/dev/null
git log --oneline -10 2>/dev/null
git branch -a 2>/dev/null | head -20

# 린터·포매터 설정 확인
ls biome.json .eslintrc* .prettierrc* 2>/dev/null

# 상위 디렉터리 workspaces 확인 (패키지 루트에서 실행 시 모노레포 감지)
[ -f ../package.json ] && python3 -c "
import json
try:
  d=json.load(open('../package.json'))
  ws=d.get('workspaces')
  print('상위 workspaces:', ws if ws else '없음')
except: pass
" 2>/dev/null

# pnpm 워크스페이스 감지 (workspaces 키와 별도 형태)
[ -f pnpm-workspace.yaml ] && echo "pnpm-workspace.yaml 감지 — 모노레포 가능성"
[ -f ../pnpm-workspace.yaml ] && echo "상위 pnpm-workspace.yaml 감지 — 모노레포 패키지 루트일 가능성"
```

파악 항목:
- **기존 하네스 구조** — `CLAUDE.md`·`.claude/`·`docs/` 존재 여부. 있으면 내용 파악 후 충돌 지점 메모
- 언어·프레임워크 (Next.js / FastAPI / Go 등)
- 모노레포 여부 (① 현재 `package.json` `workspaces` 키 ② **`pnpm-workspace.yaml`** ③ `apps/`·`packages/` 하위 독립 패키지 ④ **패키지 루트 실행 시** 상위 `../package.json` `workspaces` 또는 `../pnpm-workspace.yaml`)
- FE / BE / 풀스택 구분
- 빌드·개발 서버 명령
- 브랜치 전략 (git log 패턴으로 추론)
- 커밋 접두사 패턴 (최근 커밋 10개에서 추출)
- 이슈 트래커 (README.md 또는 `.github/` 폴더 확인)
- 도메인 목록 — FE: `pages/`·`views/`·`features/` 하위 1단계 폴더 / BE: `routes/`·`controllers/`·`handlers/` 하위 1단계 폴더

---

## Step 2 — Q&A

Step 1에서 확인하지 못한 항목만 질문한다. **한 번에 모아서 한다.**

> **모호한 답변 처리 규칙**: "그냥 기본으로", "잘 모르겠어요" 등 불명확한 답변을 받으면
> 재질문 1회 후에도 불명확하면 아래 각 항목의 기본값을 적용하고 사용자에게 기본값을 명시한다.
> 기본값 없이 임의 추정 금지.

```
[프로젝트 초기화 Q&A]

Q1. 이 서비스 이름을 뭐로 할까요?
    → docs 폴더명·에이전트 파일명에 사용됩니다.
    예: web-app, portal, dashboard
    → 모노레포인 경우: 구축할 패키지명을 입력 (예: web, admin). 패키지가 여러 개면 하나씩 순차 진행.

Q2. 주로 작업할 영역은? (FE / BE / 풀스택)

Q3. CLAUDE.md를 팀 공유(git 추적)할까요, 개인 설정(gitignore)으로 할까요?
    A) 팀 공유 — git 관리, 팀 전체 적용
    B) 개인 설정 — 로컬에만 적용

Q4. 커스텀 에이전트를 어디에 둘까요?
    A) 전역 (~/.claude/agents/) — 여러 프로젝트 재사용
    B) 프로젝트 (.claude/agents/) — 이 프로젝트 전용

Q5. 브랜치 전략은?
    → Step 1의 git log 분석 결과를 먼저 제시하고 맞는지 확인한다.
      분석으로 확인이 안 됐거나 신입인 경우 팀장에게 먼저 확인 후 답변.

    일반적인 패턴:
    - develop 기준: develop에서 분기 → task/<이슈번호> → develop으로 PR
    - main 기준:    main에서 분기 → feature/<이슈번호> → main으로 PR
    - 트렁크 기반:  main에 직접 커밋 (소규모 팀)

    확인 항목: base 브랜치명 / feature 브랜치 네이밍 규칙 / PR 대상 브랜치

Q6. Claude Code가 접근해야 할 외부 경로가 있나요?
    → 이 프로젝트 폴더 바깥에 있는 디렉터리를 Claude Code가 읽어야 하는 경우에만 입력.
      해당하지 않으면 "없음".

    해당하는 경우 예시:
    - Obsidian 등 개인 노트 Vault가 있고 Claude Code와 연동하고 싶을 때
      (예: /Users/홍길동/Documents/Dev-Vault)
    - 팀 공용 문서 저장소가 로컬에 별도로 있을 때
    - 하네스 폴더가 이 프로젝트 외부에 있을 때

    → install.sh를 사용했다면 하네스 폴더는 이미 자동 등록됨.
      위 경우에 해당하지 않으면 "없음".

[Step 1에서 불명확한 경우만 추가 질문]
Q7. 커밋 접두사 규칙이 있나요? (예: [FE] / feat: / 없음)
Q8. Playwright MCP UI 검증 에이전트가 필요한가요? (y/N)
    → Q2=BE이면 이 질문을 건너뛴다. UI 없는 BE 전용 프로젝트에는 불필요.
```

---

## Step 3 — docs/ 구조 생성

Q1 서비스명과 프로젝트 유형으로 경로를 결정한다.

**기존 docs/ 구조가 있는 경우 — 사용자에게 명시적으로 묻는다:**

기존 `docs/` 디렉토리에 파일·하위폴더가 있으면(예: 사전 작성한 plans 자료, 기존 경로 `docs/status/`), 신규 하네스 docs와 충돌·혼재 가능성이 있다. 자동 처리 금지. 다음 옵션을 사용자에게 제시:

```
docs/ 디렉토리에 기존 자료가 있습니다:
[ls -la docs/ 결과 표시]

어떻게 처리할까요?
(a) 그대로 두고 docs/<서비스명>/ 만 추가 — 기존 자료와 신규 하네스 docs 공존 (가장 보수적)
(b) docs/<서비스명>/history/ 로 이관 — 기존 자료를 회고 자산으로 보관
(c) 직접 정리 후 진행 — 사용자가 수동 정리 후 알려주세요
(d) 기존 경로(docs/status/ 등)를 그대로 쓰고 docs/<서비스명>/ 하위로 옮기지 않음 — CLAUDE.md 진입 경로를 그에 맞게 작성
```

사용자 응답 전까지 docs/ 디렉토리를 수정하지 않는다.

**DOCS_BASE 결정 기준 (`$BASE` 변수):**

| 프로젝트 유형 | BASE 값 | 예시 |
|---|---|---|
| 단일 앱 (레포 루트 실행) | `docs/<서비스명>` | `docs/portal` |
| 모노레포 루트 통합형 | `docs/<서비스명>` | `docs/web` |
| 모노레포 패키지별 (패키지 루트 실행) | `docs` | `<패키지>/docs` |

이 `$BASE` 값을 이후 Step 4·5·9·10 전체에서 동일하게 사용한다. 결정 즉시 메모.

**Step 1 분석 결과에 따라 아래 중 하나만 실행한다:**

단일 앱인 경우:
```bash
SERVICE="<Q1 서비스명>"
mkdir -p docs/$SERVICE/{status,plans,history,agent,pages,git-workflow}
```

모노레포인 경우 (`workspaces` 키 존재 또는 `apps/`·`packages/` 하위 독립 패키지):
구축할 패키지를 사용자에게 먼저 확인한다. 패키지가 여러 개면 하나씩 순차 반복한다.
```bash
# 패키지별 docs — Q1 답변 패키지 경로 사용
mkdir -p <패키지경로>/docs/{status,plans,history,agent,pages,git-workflow}
```

빈 파일 생성:
```bash
# 단일 앱 / 모노레포 루트 통합형 (레포 루트에서 실행):
BASE=docs/$SERVICE
# 모노레포 패키지별 (패키지 루트에서 실행):
# BASE=docs   ← $SERVICE 하위 불필요, 패키지 루트 기준 docs/ 직접 사용
# ↑ $BASE 값은 이후 Step 4·5·9·10(빌드_검증_템플릿)에서 동일하게 사용

touch $BASE/status/HANDOFF_NOW.md
touch $BASE/plans/HANDOFF.md
touch $BASE/history/세션_노트.md
touch $BASE/agent/README.md
touch $BASE/agent/architecture.md
touch $BASE/agent/conventions.md
touch $BASE/git-workflow/branch-commit.md
```

> 모노레포 구조 상세: `<하네스경로>/Claude Code/docs_디렉토리_구조.md`

---

## Step 4 — CLAUDE.md 작성

Step 1 분석 결과 + Q&A 답변으로 프로젝트 루트에 `CLAUDE.md` 생성.

> **템플릿 파일 경로 해석**: 아래 Step 4~9의 `<하네스경로>`는 **하네스 설치 절대경로**다.
> Read로 읽기 전에 아래 명령으로 실제 절대경로를 확인하고, `<하네스경로>`를 그 값으로 대체한다:
> ```bash
> python3 -c "
> import json, pathlib
> s = pathlib.Path.home() / '.claude/settings.json'
> data = json.loads(s.read_text()) if s.exists() else {}
> dirs = data.get('permissions', {}).get('additionalDirectories', [])
> harness = [d for d in dirs if '하네스' in d or 'harness' in d.lower()]
> print('하네스 경로:', harness[0] if harness else '(settings.json에 없음 — install.sh 재실행 또는 경로 직접 확인)')
> "
> ```
> 확인된 절대경로를 `<하네스경로>`로 대체해 Read를 실행한다.
> 예: `<하네스경로>/Claude Code/템플릿/CLAUDE.md_템플릿.md`

**아래 파일을 Read로 먼저 읽어 템플릿을 확인한 뒤 작성한다:**
`<하네스경로>/Claude Code/템플릿/CLAUDE.md_템플릿.md`

**기존 CLAUDE.md가 있는 경우**: 덮어씌우기 전에 반드시 사용자에게 아래 선택지를 제시한다.

| 옵션 | 처리 | 추천 상황 |
|------|------|---------|
| **병합** | 기존 팀 규칙 유지 + 하네스 필수 섹션(STEP 0·STEP 3) 추가 | 기존 CLAUDE.md가 팀 규칙을 담고 있는 경우 |
| **대체** | 기존 파일을 `CLAUDE.md.bak`으로 백업 후 템플릿으로 새로 작성 | 기존 내용이 최소한이거나 하네스 재구축인 경우 |
| **건너뜀** | CLAUDE.md를 수정하지 않음 | 기존 파일을 그대로 유지하고 싶은 경우 |

사용자 선택 후 그에 따라 처리. **선택 전까지 파일 수정 금지.**

포함 항목:
- 프로젝트 개요 (이름·목적·기술 스택)
- 작업 영역 판별 기준 (Q2·Step 1 도메인 목록 기반 — FE/BE/풀스택 구분 포함)
- 진입 문서 경로 (`$BASE/status/HANDOFF_NOW.md`)
- 작업 중 강제 규칙 (API 레이어 패턴·상태 관리 제약 등 프로젝트별 금지 사항)
- 브랜치·커밋 규칙 (Q5·Q7 기반)
- 빌드·개발 서버 명령
- 서브에이전트 호출 규칙 (Q2 기반 — [서비스명]-dev, [서비스명]-doc-writer 매핑)
- 팀 프로세스 (이슈 생성·커밋·PR 참조 문서 경로 — `.github/PULL_REQUEST_TEMPLATE.md` 확인)
- 등록 스킬 목록: 아래 명령으로 실제 설치된 스킬 전체 확인 후 CLAUDE.md에 기재
  ```bash
  ls ~/.claude/skills/ .claude/skills/ 2>/dev/null | sort -u
  ```
  하네스 기본 스킬:

  | 스킬 | 용도 |
  |------|------|
  | `/session-close` | 세션 종료 — HANDOFF 3종 갱신 |
  | `/project-fix` | QA·버그 이슈 → 서브이슈 생성 + 브랜치 준비 |
  | `/project-pr` | PR 생성 — 이슈 연결·Co-Authored-By 포함 |
  | `/project-issue` | GitHub 이슈 인터랙티브 생성 |
  | `/document-review` | 문서 세트 시나리오 검증·이슈 수정 |

  개인 스킬(--personal 설치 시): `/daily-note`·`/standup`·`/meeting-note`·`/til`·`/weekly-retro`·`/weekly-meeting-update`

  > **프로젝트 전용 스킬이 있는 경우**: 범용 스킬명 대신 프로젝트 전용 스킬명을 기재한다.
  > 예: `my-project` → `/session-close` 대신 `/my-project-session-close`, `/project-fix` 대신 `/my-project-fix`
- 세션 종료 절차 (`/session-close` — 프로젝트 전용 스킬이 있으면 해당 스킬명으로 교체)

Q3 답변에 따라:
- 팀 공유 → `.gitignore`에 추가하지 않음
- 개인 설정 → `.gitignore`에 `CLAUDE.md` 추가

**모노레포인 경우**: 루트 CLAUDE.md 외에 패키지별로 더 제한적인 규칙이 필요한지 사용자에게 확인한다. 필요하면 해당 패키지 루트에 추가 CLAUDE.md 작성 (충돌 시 더 제한적인 규칙 우선).

---

## Step 5 — 에이전트 컨텍스트 문서 작성

Step 1 분석 결과로 `$BASE/agent/` 문서를 채운다.
**아래 파일을 Read로 먼저 읽어 템플릿을 확인한 뒤 작성한다:**
`<하네스경로>/Claude Code/템플릿/agent_문서_템플릿.md`

**README.md**: 이 프로젝트의 에이전트 목록과 각 파일의 역할을 한줄로 요약 작성.
Step 6에서 에이전트를 추가 정의한 뒤 목록을 업데이트한다.
```markdown
# 에이전트 컨텍스트 문서

- architecture.md — 앱 구조·인증·상태관리 패턴
- conventions.md — 린터·커밋·네이밍 컨벤션
- [서비스명]-dev.md — 코드 작성 전담 에이전트 정의
- [서비스명]-doc-writer.md — 문서 갱신 전담 에이전트 정의
```

**architecture.md**: Q2 기반으로 항목을 결정한다.
- FE: 앱 종류(SPA/SSR) · 레이아웃 구조 · 인증 방식 · 상태관리 패턴
- BE: 서버 종류(REST/GraphQL/gRPC) · 라우팅 구조 · 인증 방식 · DB 패턴
- 풀스택: FE·BE 항목 모두 기재

**conventions.md**: 린터·포매터 설정 분석 결과 (없으면 git log 추론값)

**design-system.md** (FE·풀스택): `tailwind.config.ts` 또는 CSS 변수 파일 확인 후 작성. 없으면 생략.

---

## Step 6 — 커스텀 에이전트 정의

Q4 답변 위치에 아래 에이전트를 생성한다.
**아래 파일을 Read로 먼저 읽어 에이전트 정의 형식을 확인한 뒤 작성한다:**
`<하네스경로>/Claude Code/에이전트_정의_가이드.md`

**필수 (항상 생성):**
- `[서비스명]-dev.md` — 코드 작성 전담
- `[서비스명]-doc-writer.md` — 문서 갱신 전담

**다중 패키지 모노레포 에이전트 분리 기준:**

| 조건 | 구성 |
|------|------|
| 패키지 2개 이하 | 패키지마다 별도 에이전트 (`web-dev.md`, `admin-dev.md`) |
| 패키지 3개 이상 · 스택 동일 | 공통 에이전트 1개 + 패키지명 분기 주석 |
| 패키지 3개 이상 · 스택 상이 | 핵심 2~3개 별도 에이전트, 나머지 공통 1개 |

**선택 (Q8 = y인 경우):**
- `[서비스명]-playwright-validator.md` — UI 검증 전담

저장 위치:
- Q4-A: `~/.claude/agents/`
- Q4-B: `.claude/agents/`

**기존 에이전트 파일이 있는 경우**: 같은 이름의 파일이 존재하면 덮어씌우기 전에 기존 내용을 확인하고 사용자에게 갱신 여부를 확인한다.

**에이전트 파일 존재 검증 (생성 후 필수):**

```bash
AGENT_DIR="<Q4 답변 경로>"  # ~/.claude/agents/ 또는 .claude/agents/
ls "$AGENT_DIR"/*.md 2>/dev/null || echo "⚠ 에이전트 파일이 없습니다. 경로($AGENT_DIR)를 확인하세요."
```

경로 불일치가 감지되면 Q4 답변을 재확인하고 올바른 위치에 파일을 생성한다.

---

## Step 7 — settings.json + 훅 스크립트 설정

### 7-A. additionalDirectories 설정 (Q6 답변 기반)

Q6에서 외부 경로를 받은 경우에만 실행한다. "없음"이면 건너뜀.

```bash
python3 - << 'EOF'
import json, pathlib
path = pathlib.Path.home() / ".claude" / "settings.json"
data = json.loads(path.read_text()) if path.exists() else {}
data.setdefault("permissions", {}).setdefault("additionalDirectories", [])
vault = "<Q6 답변 경로>"
if vault not in data["permissions"]["additionalDirectories"]:
    data["permissions"]["additionalDirectories"].append(vault)
path.write_text(json.dumps(data, indent=2, ensure_ascii=False))
print("완료:", path)
EOF
```

### 7-B. 훅 스크립트 설치 여부 확인

개발문서 자동 감지·경고가 필요하면 훅을 설치한다. 불필요하면 건너뜀.

```bash
ls ~/.claude/hooks/ 2>/dev/null && echo "훅 폴더 존재" || echo "미설치"
```

- **훅 폴더가 없으면 (처음 설치):**
  ```bash
  bash <하네스경로>/install.sh --hooks
  ```
  → `check-source-doc.sh` + `pre-commit-doc-check.sh` 복사·실행 권한 설정·settings.json hooks 자동 등록

- **이미 있으면** → 7-C 경로 패턴 설정으로 바로 진행

### 7-C. hooks-config.sh 자동 생성

Phase 1-B에서 파악한 소스 경로로 `.claude/hooks-config.sh`를 자동 생성한다.
훅 스크립트가 이 파일을 자동 소싱하므로 각 팀원이 훅을 개별 수정할 필요 없다.

**① 변수 값 결정 (Phase 1-B 분석 결과 활용)**

| 변수 | 결정 방법 |
|---|---|
| `FE_PATTERN` | Phase 1-B 소스 경로 + `(pages\|components\|hooks\|api)/([^/]+)/` |
| `FE_DOC_BASE` | Phase 3에서 생성한 docs 경로 (`docs/<서비스명>/pages`) |
| `FE_PROJECT` | Q1 서비스명 |
| `FE_COMMIT_PATTERN` | `^(<소스경로>)/.*\.(js\|ts\|tsx\|jsx)$` |
| `FE_DOMAIN_EXTRACT` | `s\|<소스경로>/pages/([^/]+)/.*\|\1\|; s\|<소스경로>/views/([^/]+)/.*\|\1\|` |
| `FE_DOC_DIR_BASE` | `docs/<서비스명>/pages` |

BE·풀스택이면 `BE_*` 변수도 동일 방식으로 결정한다.

> **Q2=BE인 경우 (FE 없는 순수 백엔드)**: FE 섹션 변수는 `FE_PATTERN=""` 한 줄만 두어 FE 훅을 비활성화한다. BE 섹션은 주석을 해제하고 실제 경로로 채운다.

**② 파일 생성 (소스 경로·서비스명을 실제 값으로 채워 Write)**

사용자에게 아래 내용을 먼저 보여주고 확인받은 뒤 작성한다:
> "아래 내용으로 `.claude/hooks-config.sh`를 생성합니다. 경로가 맞나요?"

**풀스택·FE 전용 프로젝트 템플릿:**
```bash
# .claude/hooks-config.sh
# 팀 공유 훅 설정 — git 추적 대상 (커밋 필수)

# ── FE 소스 경로 ──────────────────────────────────────────────
FE_PATTERN="<소스경로>/(pages|components|hooks|api)/([^/]+)/"
FE_DOC_BASE="docs/<서비스명>/pages"
FE_PROJECT="<서비스명>"

FE_COMMIT_PATTERN="^(<소스경로>)/.*\.(js|ts|tsx|jsx)$"
FE_DOMAIN_EXTRACT='s|<소스경로>/pages/([^/]+)/.*|\1|; s|<소스경로>/views/([^/]+)/.*|\1|'
FE_DOC_DIR_BASE="docs/<서비스명>/pages"

# ── BE 소스 경로 (BE·풀스택만) ────────────────────────────────
# BE_PATTERN="<BE소스경로>/(routes|services|handlers|models)/([^/]+)"
# BE_DOC_BASE="docs/<BE서비스명>/pages"
# BE_PROJECT="<BE서비스명>"
# BE_COMMIT_PATTERN="^(<BE소스경로>)/.*\.(py|go|java|kt|rs)$"
# BE_DOMAIN_EXTRACT='s|<BE소스경로>/routes/([^/]+)/.*|\1|; s|<BE소스경로>/services/([^/]+)/.*|\1|'
# BE_DOC_DIR_BASE="docs/<BE서비스명>/pages"
```

**BE 전용 프로젝트 템플릿 (Q2=BE):**
```bash
# .claude/hooks-config.sh
# 팀 공유 훅 설정 — git 추적 대상 (커밋 필수)

# ── FE 없음 — FE 훅 비활성화 ──────────────────────────────────
FE_PATTERN=""

# ── BE 소스 경로 ──────────────────────────────────────────────
BE_PATTERN="<BE소스경로>/(routes|services|handlers|models)/([^/]+)"
BE_DOC_BASE="docs/<서비스명>/pages"
BE_PROJECT="<서비스명>"
BE_COMMIT_PATTERN="^(<BE소스경로>)/.*\.(py|go|java|kt|rs)$"
BE_DOMAIN_EXTRACT='s|<BE소스경로>/routes/([^/]+)/.*|\1|; s|<BE소스경로>/services/([^/]+)/.*|\1|'
BE_DOC_DIR_BASE="docs/<서비스명>/pages"
```

**③ git 추적 + 커밋**

```bash
git add .claude/hooks-config.sh
git commit -m "docs: [공통] 팀 훅 경로 설정 파일 추가"
```

팀원은 `git pull` 후 자동 적용된다.

---

## Step 8 — 메모리 초기화

```bash
PROJECT_PATH=$(pwd | sed 's|/|-|g')
echo "메모리 경로: ~/.claude/projects/${PROJECT_PATH}/memory/"
ls ~/.claude/projects/${PROJECT_PATH}/memory/ 2>/dev/null || echo "(첫 세션 후 자동 생성)"
```

> 메모리 폴더는 Claude Code가 첫 세션 시 자동 생성한다. 수동 mkdir 불필요.

MEMORY.md가 없으면 최소 구조로 생성:
```markdown
# Memory Index
## Feedback
## Reference
```

Q&A 결과를 아래 기준으로 저장한다:

- **작업 규칙·팀 컨벤션** → `feedback_*.md`
  예: `feedback_branch_naming.md` — "브랜치는 task/<이슈번호> 형식. develop 기준."
  예: `feedback_commit_prefix.md` — "커밋 접두사: [FE] / [BE] / [공통]"

- **외부 리소스·링크** → `reference_*.md`
  예: `reference_issue_tracker.md` — "이슈는 GitHub Issues 사용. 레포: <URL>"
  예: `reference_design_tool.md` — "디자인: Figma <URL>"

---

## Step 9 — HANDOFF 3종 완성

**HANDOFF_NOW.md** (`$BASE/status/HANDOFF_NOW.md`):

**아래 파일을 Read로 먼저 읽어 전체 형식을 확인한다:**
`<하네스경로>/Claude Code/템플릿/HANDOFF_NOW_템플릿.md`

**기존 파일이 있는 경우**: 내용을 먼저 확인한다.
- 진행 중인 이슈가 없으면 → 아래 초기 상태로 작성
- 진행 중인 이슈가 있으면 → §1·§2 기존 내용을 유지하고 §2 마지막에 "하네스 구축 완료" 항목만 추가

```markdown
# <서비스명> HANDOFF NOW

> **Hot 문서** — 세션 시작 시 가장 먼저 읽는다. 항상 60줄 이하로 유지.
> 상세 히스토리 → `plans/HANDOFF.md` / 세션 기록 → `history/세션_노트.md`

---

## §1 현재 상태

| 항목 | 값 |
|---|---|
| **브랜치** | `<기본 브랜치>` |
| **활성 이슈** | 없음 |
| **빌드** | `<감지된 빌드 명령>` |
| **테스트** | `<감지된 테스트 명령>` |

**아키텍처**: <기술 스택 + 핵심 구조 한줄 요약>
**마지막 작업**: <오늘 날짜> — 하네스 초기 구축

---

## §2 다음 작업 (신규 세션)

1. 🔴 첫 이슈 생성 후 개발 착수
```

**HANDOFF.md** (`$BASE/plans/HANDOFF.md`):

**아래 파일을 Read로 먼저 읽어 전체 형식을 확인한다:**
`<하네스경로>/Claude Code/템플릿/HANDOFF_템플릿.md`

```markdown
## Session Update <오늘 날짜> (하네스 초기 구축)

### 변경 파일
- `CLAUDE.md` — 프로젝트 하네스 진입점
- `docs/<서비스명>/agent/` — README.md, architecture.md, conventions.md
- `docs/<서비스명>/git-workflow/branch-commit.md` — 브랜치·커밋 규칙
- `<에이전트 저장 위치>/` — [서비스명]-dev, [서비스명]-doc-writer

### 이슈
- 하네스 초기 구축 완료
```

**세션_노트.md** (`$BASE/history/세션_노트.md`):

**아래 파일을 Read로 먼저 읽어 전체 형식을 확인한 뒤 복사해 초기화한다:**
`<하네스경로>/Claude Code/템플릿/세션_노트_템플릿.md`

**git-workflow/branch-commit.md** (`$BASE/git-workflow/branch-commit.md`):
**아래 파일을 Read로 먼저 읽어 전체 구조를 확인한 뒤** Q5·Q7 답변으로 내용을 채운다.
`<하네스경로>/Claude Code/템플릿/git_워크플로우_템플릿.md`
```markdown
# 브랜치·커밋 규칙

## 브랜치

| 항목 | 규칙 |
|------|------|
| base 브랜치 | `<develop 또는 main>` |
| 브랜치명 | `<타입>/<이슈번호>` (예: task/1234, fix/1234) |
| PR 대상 | `<develop 또는 main>` |

## 커밋

| 항목 | 규칙 |
|------|------|
| 접두사 | `<[FE] / feat: / 없음>` |
| 형식 | `<접두사> <변경 내용> #<이슈번호>` |
| Co-Authored-By | Claude Code 작업 시 필수 |
```

**(FE·풀스택 프로젝트) 첫 기능 정리 문서**: 핵심 기능 1개 선택 → `$BASE/pages/<도메인>/FE_<기능명>.md` 작성.
**아래 파일을 Read로 먼저 읽어 템플릿을 확인한 뒤 작성한다:**
`<하네스경로>/Claude Code/템플릿/FE_기능정리_템플릿.md`

**(BE 프로젝트) 첫 기능 정리 문서**: 핵심 API 도메인 1개 선택 → `$BASE/pages/<도메인>/BE_<기능명>.md` 작성.
**아래 파일을 Read로 먼저 읽어 템플릿을 확인한 뒤 작성한다:**
`<하네스경로>/Claude Code/템플릿/BE_기능정리_템플릿.md`

**(BE·풀스택 프로젝트) API 검증 전략 문서**: `$BASE/agent/api-verification.md` 작성.
**아래 파일을 Read로 먼저 읽어 템플릿을 확인한 뒤** Step 1에서 감지한 실제 명령어로 플레이스홀더를 채운다:
`<하네스경로>/Claude Code/템플릿/api-verification_템플릿.md`

교체 항목:
- `<초기_구축_날짜>` → 오늘 날짜
- `<단위테스트_명령>` → Step 1에서 감지한 테스트 명령 (예: `pytest tests/ -v`)
- `<통합테스트_명령>` → 통합 테스트 명령 (없으면 단위 테스트 명령과 동일)
- `<서버_기동_명령>` → Step 1에서 감지한 서버 실행 명령 (예: `uvicorn app.main:app --reload`)
- `<서버_포트>` → 감지된 포트 (예: `8000`)
- `<서비스명>` → Q1 서비스명
- `<마이그레이션_*_명령>` → 마이그레이션 도구 명령 — 없으면 해당 섹션 삭제

작성 후 `$BASE/agent/README.md`에 아래 항목을 추가한다:
```markdown
- api-verification.md — API 검증 3단계 전략 (단위·통합·실서버)
```

**(FE·풀스택 프로젝트) UI 검증 전략 문서**: `$BASE/agent/ui-verification.md` 작성.
**아래 파일을 Read로 먼저 읽어 템플릿을 확인한 뒤** Step 1에서 감지한 실제 명령어로 플레이스홀더를 채운다:
`<하네스경로>/Claude Code/템플릿/ui-verification_템플릿.md`

교체 항목:
- `<초기_구축_날짜>` → 오늘 날짜
- `<단위테스트_명령>` → Step 1에서 감지한 테스트 명령 (예: `pnpm test`)
- `<dev_서버_명령>` → Step 1에서 감지한 dev 명령 (예: `pnpm dev`)
- `<dev_서버_포트>` → 감지된 포트 (예: `3000`)
- `<서비스명>` → Q1 서비스명

작성 후 `$BASE/agent/README.md`에 아래 항목을 추가한다:
```markdown
- ui-verification.md — UI 검증 3단계 전략 (단위·Headless·MCP)
```

---

## Step 10 — 검증

**빌드 결과 검증 (먼저 실행):**
아래 파일을 Read로 먼저 읽어 검증 스크립트를 확인한다:
`<하네스경로>/Claude Code/템플릿/빌드_검증_템플릿.md`

`SERVICE`와 `AGENT_DIR`을 실제 값(Q1·Q4 답변)으로 교체한 뒤 스크립트를 실행한다.
- ✗ 누락 항목이 있으면 → 빌드_검증_템플릿.md의 "보완 경로" 표에 따라 해당 Step으로 돌아가 즉시 보완 후 재실행
- ⚠ 비어 있는 파일이 있으면 → 해당 Step으로 돌아가 내용 채우기
- 전량 ✓ 통과 후 아래 동작 확인으로 진행한다

**CLAUDE.md 동작 확인:**
```
이 프로젝트 작업 시작할게
```
→ 에이전트가 자동으로 HANDOFF_NOW.md를 읽고 §1·§2 요약 출력하면 정상.
출력이 없으면 CLAUDE.md의 진입 문서 경로 확인.

**훅 동작 확인 (Step 7에서 훅을 설정한 경우):**
- 소스 파일 하나를 수정 → PostToolUse 메시지 출력 확인
- **기대 결과**: `⚠️ [FE 문서 미존재] ...` / `⚠️ [BE 문서 미존재] ...` 또는 `📄 [FE 문서 확인] ...` / `📄 [BE 문서 확인] ...` 메시지
- **실패 신호**: 아무 메시지도 없으면 아래 순서로 진단한다

  ```
  [메시지 미출력 시 진단 순서]
  (a) 실행 권한: ls -la ~/.claude/hooks/ | grep check-source-doc
      → -rwxr-xr-x 형태여야 함. x 없으면: chmod +x ~/.claude/hooks/check-source-doc.sh
  (b) 플레이스홀더 미수정: grep "<소스경로>" ~/.claude/hooks/check-source-doc.sh
      → 출력이 있으면 .claude/hooks-config.sh 가 없거나 패턴 미설정
        → FE 프로젝트: FE_PATTERN 확인 / BE 프로젝트: BE_PATTERN 확인 (FE_PATTERN="" 여부도 확인)
        → .claude/hooks-config.sh 생성 또는 7-C 재실행 (hooks-config.sh 자동 생성)
  (c) settings.json 등록 확인: python3 -c "import json,pathlib; d=json.loads(pathlib.Path('~/.claude/settings.json').expanduser().read_text()); print(d.get('hooks','미등록'))"
      → hooks 키가 없으면: bash <하네스경로>/install.sh --hooks 재실행
  (d) 소스 경로 패턴 불일치: 수정한 파일 경로가 check-source-doc.sh 내 FE/BE 패턴과 일치하는지 확인
  ```

**gitignore 항목 추가:**
```gitignore
*.skill
.claude/settings.json
.claude/settings.local.json
**/docs/testing/screenshots/
```

---

## Step 11 — 완료 보고

```
[Project Init 완료]

생성 파일:
- CLAUDE.md
- docs/<서비스명>/status/HANDOFF_NOW.md
- docs/<서비스명>/plans/HANDOFF.md
- docs/<서비스명>/history/세션_노트.md
- docs/<서비스명>/agent/README.md
- docs/<서비스명>/agent/architecture.md
- docs/<서비스명>/agent/conventions.md
- docs/<서비스명>/git-workflow/branch-commit.md
- .claude/hooks-config.sh  ← git 커밋 필수
- <에이전트 위치>/[서비스명]-dev.md
- <에이전트 위치>/[서비스명]-doc-writer.md

조건부 파일 (BE·풀스택인 경우):
- docs/<서비스명>/agent/api-verification.md
- docs/<서비스명>/pages/<도메인>/BE_<기능명>.md

조건부 파일 (FE·풀스택인 경우):
- docs/<서비스명>/agent/design-system.md
- docs/<서비스명>/agent/ui-verification.md
- docs/<서비스명>/pages/<도메인>/FE_<기능명>.md

다음 단계:
1. CLAUDE.md 내용 검토 후 팀 규칙에 맞게 조정
2. /project-issue 로 첫 이슈 생성
3. 작업 시작
```
