---
tags: [하네스, readme, 진입점]
updated: 2026-05-07
---

# Claude Code 하네스

Claude Code를 프로젝트에 적용하기 위한 스킬·문서·설정 패키지.

> 영문 문서: [README.md](./README.md)
> 전체 구축 가이드 → [공용_하네스_구축_가이드.md](공용_하네스_구축_가이드.md)

---

## 지원 플랫폼

| 플랫폼 | 지원 | 비고 |
|--------|------|------|
| **macOS 10.15+** | ✅ | 완전 지원 · 검증됨 |
| **Linux (Ubuntu 20.04+)** | ✅ | bash 4.0+ 필요 · 검증됨 |
| **Windows (WSL2)** | ✅ | Ubuntu 20.04+ on WSL2 권장 |
| **Windows (native)** | 🧪 | 실험적 — `install.ps1` 포팅 완료, 실환경 검증 진행 중. PowerShell 5.1+ (실제 `python` + 훅은 Git Bash 필요) |

---

## 빠른 시작

### 0. 사전 준비

> **요구 버전**: Claude Code **1.x 이상**, Node.js **18 이상**
> `claude --version`으로 확인. 구버전이면 `npm update -g @anthropic-ai/claude-code`로 업데이트.

```bash
# Claude Code CLI 설치 (없으면)
npm install -g @anthropic-ai/claude-code   # Node.js 18 이상 필요
claude --version                            # 설치 확인
```

### 1. 하네스 폴더 배치

프로젝트 레포와 같은 레벨에 배치한다.

```
workspace/
  MyProject/    ← 작업할 레포
  하네스/        ← 이 폴더
```

### 2. 부트스트랩 실행

```bash
bash 하네스/install.sh
```

실행 결과:
- `~/.claude/skills/` — 프로젝트 스킬 설치
- `~/.claude/settings.json` — 모델·경로 설정
- 개인 생산성 스킬 설치 여부 대화형 선택

개인 생산성 스킬까지 한 번에 설치하려면:
```bash
bash 하네스/install.sh --personal
```

FE/풀스택 프로젝트에서 훅 스크립트(FE 문서 자동 감지)를 설치하려면:
```bash
bash 하네스/install.sh --hooks
```

**Windows native (PowerShell)** — bash 대신 `install.ps1` 사용:
```powershell
powershell -ExecutionPolicy Bypass -File 하네스\install.ps1            # 프로젝트 스킬 (항상)
powershell -ExecutionPolicy Bypass -File 하네스\install.ps1 -Personal  # + 개인 생산성 스킬
powershell -ExecutionPolicy Bypass -File 하네스\install.ps1 -Hooks     # + FE 문서 체크 훅
powershell -ExecutionPolicy Bypass -File 하네스\install.ps1 -Yes       # 비대화형 (기본값 진행)
```

> `install.ps1`은 `install.sh`의 네이티브 포팅 — 실제 `python` 탐지(Windows Store `python3` 스텁 회피), `cp`/`rm` 대신 `robocopy`, `settings.json`의 한글 경로 보존. 훅 command는 `bash ...`라 발동하려면 `PATH`에 Git Bash가 있어야 한다.
>
> ⚠️ native Windows 지원은 **실험적**입니다 — 임시 디렉터리 dry run으로 확인했으나 실환경 검증은 진행 중. 완전 검증된 경로가 필요하면 WSL2를 사용하세요.

> **훅 설치 후**: 이후 `/project-init` 실행 시 소스 경로를 자동 분석해
> `.claude/hooks-config.sh`를 생성한다. 수동 조정이 필요하면 `Claude Code/훅_스크립트_전문.md` 참조.

> **GitHub 스킬 사용 전 필수**: `gh auth login` 으로 GitHub CLI 인증을 완료해야
> `/project-fix`, `/project-pr`, `/project-issue`가 정상 동작한다.

### 3. 프로젝트 하네스 구축

```bash
cd MyProject
claude
```

Claude에게 입력:
```
/project-init
```

코드베이스 자동 분석 → Q&A → `CLAUDE.md` + 에이전트 정의 + HANDOFF 전체 구축.

### 4. 설치 검증

```bash
# 스킬 설치 확인
ls ~/.claude/skills/ | grep -E "project-init|project-fix|project-issue|project-pr|session-close|document-review"

# settings.json 확인
python3 -c "
import json, pathlib
d = json.loads(pathlib.Path('~/.claude/settings.json').expanduser().read_text())
print('model:', d.get('model', '(미설정)'))
print('additionalDirectories:', len(d.get('permissions',{}).get('additionalDirectories',[])), '개')
"

# GitHub CLI 인증 확인 (project-fix / project-pr / project-issue 사용 시)
gh auth status
```

### 5. 업그레이드

새 버전 하네스로 스킬·훅을 덮어쓰려면 `--force` 플래그를 사용한다.

```bash
# 프로젝트 스킬 강제 업그레이드
bash 하네스/install.sh --force

# 훅까지 함께 강제 업그레이드
bash 하네스/install.sh --force --hooks
```

Windows native (PowerShell):
```powershell
powershell -ExecutionPolicy Bypass -File 하네스\install.ps1 -Force         # 프로젝트 스킬 강제 업그레이드
powershell -ExecutionPolicy Bypass -File 하네스\install.ps1 -Force -Hooks  # + 훅
```

> `--force` 없이 재실행하면 이미 존재하는 스킬·훅을 스킵한다.

> **`--force --hooks` 주의**: 훅 스크립트 자체를 덮어쓰므로, 스크립트 내 변수(`FE_PATTERN` 등)를
> 직접 수정한 경우 설정이 초기화됩니다. 팀 공유 방식(`.claude/hooks-config.sh`)을 사용하면
> 프로젝트 레포에 설정이 보존되므로 영향받지 않습니다.

> **개인 스킬(`daily-note`, `standup` 등)은 `--force`로 덮어써지지 않습니다.**
> 노트 경로 설정이 보존됩니다. 개인 스킬을 업그레이드하려면 개별 삭제 후 재설치하세요.

특정 스킬만 개별 업그레이드하려면:
```bash
rm -rf ~/.claude/skills/<스킬명>   # 기존 스킬 제거
bash 하네스/install.sh              # 재설치
```

현재 설치된 하네스 버전 확인:
```bash
cat 하네스/VERSION
```

**Claude Code 버전 업 후 호환성 확인 절차 (S56):**

Claude Code 메이저 업데이트 후 훅·스킬이 정상 동작하지 않으면:
1. `claude --version` 으로 현재 버전 확인
2. `하네스/CHANGELOG.md` 에서 해당 버전과 하네스 버전의 호환 여부 확인
3. 훅 stdin 포맷 변경 시: `hooks/pre-commit-doc-check.sh` 상단 INPUT 파싱 로직 점검
4. 스킬 로드 방식 변경 시: `claude --help` 또는 공식 문서에서 `--skills-path` 옵션 확인
5. 검증 완료 후 `하네스/VERSION` 파일 업데이트 및 `CHANGELOG.md` 에 호환 버전 기록

---

## 기대치 설정

`/project-init`이 만들어주는 건 **하네스의 골격**이다. 도메인 특정 함정·강제 규칙은 운영하면서 누적된다.

| 시점 | CLAUDE.md 줄수 | 누적 자산 |
|------|---------------|-----------|
| 부트스트랩 직후 | ~50줄 | 4원칙 + 기본 STEP 0~3 |
| 1개월 운영 후 | ~120줄 | 첫 함정 발견 + 도메인 분기 시작 |
| 6개월 운영 후 | ~250줄 | 5~6개 도메인 강제 규칙 + 진화 이력 |

자세한 진화 흐름은 [`examples/`](examples/) 디렉토리 참조:
- `01-initial.md` — 부트스트랩 직후 골격
- `02-after-1-month.md` — 1개월 후 첫 함정 추가
- `03-after-6-months.md` — 6개월 후 누적된 풀 예시
- `04-team.md` — 팀(2~5인) 공유 패턴

처음부터 풍부한 CLAUDE.md를 기대하면 실망한다 — 그건 운영의 결과물이지 부트스트랩의 출력이 아니다.

---

## 실행 흐름 예시

> 실제 환경·옵션에 따라 출력은 다를 수 있다. 아래는 일반적 흐름 참고용.

### 1. `install.sh --personal --hooks` 실행

```
$ bash 하네스/install.sh --personal --hooks

[1/4] Claude Code 스킬 설치 중...
  ✓ /project-init
  ✓ /project-fix
  ✓ /project-issue
  ✓ /project-pr
  ✓ /session-close
  ✓ /document-review

[2/4] 개인 스킬 설치 중...
  ✓ /daily-note · /standup · /weekly-retro · /til · /meeting-note · /weekly-meeting-update
  → 노트 경로 설정
  경로: /Users/<사용자명>/Documents/Dev-Vault
  ✓ <개인_노트_경로> 플레이스홀더 치환 완료

[3/4] 훅 스크립트 설치 중...
  ✓ pre-commit-doc-check.sh
  ✓ check-source-doc.sh
  ✓ ~/.claude/settings.json 훅 등록

[4/4] 검증
  ✓ 12개 스킬 설치 확인
  ✓ settings.json 훅 등록 확인

완료. claude 실행 후 /project-init 으로 시작하세요.
```

### 2. `/project-init` 실행 (Q&A 발췌)

```
You: /project-init

Claude:
[Phase 1 — 프로젝트 분석]
  - 감지된 스택: Next.js 15 + TypeScript + pnpm 워크스페이스
  - 모노레포 구조: apps/web, packages/ui
  - 도메인: auth, dashboard, settings, profile, billing
  - 커밋 패턴: feat: / fix: / chore:

[Phase 2 — Q&A]
1) 서비스 이름?    → web
2) 주 작업 영역?   → 풀스택
3) Playwright?     → 예
... (Q&A 7개 완료)

[Phase 3~9 — 실행]
  ✓ docs/web/ 구조 생성
  ✓ CLAUDE.md 작성 (158줄)
  ✓ docs/web/agent/architecture.md, conventions.md
  ✓ ~/.claude/agents/web-dev.md, web-doc-writer.md, web-playwright-validator.md
  ✓ HANDOFF_NOW.md, HANDOFF.md, 세션_노트.md 초기화
  ✓ .claude/hooks-config.sh 자동 생성

[Phase 10 — 검증]
  ✓ 필수 파일 14개 전량 통과 / ✗ 0개 누락

하네스 구축 완료.
```

### 3. `/daily-note` 실행 결과 (아침 모드)

```
You: /daily-note 만들어줘

Claude:
[일일노트]
파일: <개인_노트_경로>/일일노트/2026-04-30.md
모드: 아침
- 할 일 3개 pre-fill
  - HANDOFF_NOW.md §2 첫 항목: "#1234 API 레이어 마이그레이션"
  - 어제 이월 1개: "디자인 토큰 정리"
  - weekly-tasks.md 오늘 분 1개
```

생성된 일일노트 미리보기:

```markdown
# 4월 30일 (목)

## 오늘 할 일
- [ ] #1234 API 레이어 마이그레이션
- [ ] 디자인 토큰 정리 (어제 이월)
- [ ] 사이드: README 콘솔 출력 예시 작성

## 작업 로그
| 시간 | 내용 | 이슈 |
|------|------|------|
|  |  |  |
```

---

## 폴더 구조

```
하네스/
  install.sh           부트스트랩 스크립트 (macOS·Linux·WSL2)
  install.ps1          부트스트랩 스크립트 (Windows native · PowerShell)
  README.md            영문 README (진입점)
  README.ko.md         이 파일 — 한국어 전체 문서
  skills/              프로젝트 워크플로우 스킬 (항상 설치)
  personal-skills/     개인 생산성 스킬 (선택 설치)
  hooks/               훅 스크립트 (--hooks 플래그로 설치)
  Claude Code/         스킬 목록·체크리스트·메모리 가이드·트러블슈팅
  설정_템플릿/          settings.json·MCP 설정_템플릿
  운영_가이드/          HANDOFF 규칙·세션 패턴·UI 검증 전략
  프롬프트/             서브에이전트 호출 패턴
  공용_하네스_구축_가이드.md  전체 구축 가이드 (상세)
```

> **README.md vs 공용_하네스_구축_가이드.md**: README.md(영문)·README.ko.md는 빠른 시작 + 스킬 목록. 프로젝트 내 팀 하네스 전체 구성(CLAUDE.md 설계·에이전트 정의·HANDOFF 구조)은 `공용_하네스_구축_가이드.md` 참조.

---

## 스킬 목록

### 프로젝트 워크플로우 (기본 설치)

| 스킬 | 용도 |
|------|------|
| `/project-init` | 새 프로젝트 하네스 초기 구축 |
| `/project-fix` | QA·버그 이슈 → 서브이슈 + 브랜치 준비 |
| `/project-issue` | GitHub 이슈 생성 |
| `/project-pr` | PR 생성 (이슈 연결·Co-Authored-By 포함) |
| `/session-close` | 세션 종료 — HANDOFF 갱신 |
| `/document-review` | 문서 구조·완전성 검증 |
| `/harness-audit` | 하네스 끊긴 배선(삭제·리네임된 에이전트/스킬/문서 참조) 스캔 |
| `/doc-drift` | 기능 문서(FE_*.md·BE_*.md)가 참조 source보다 노후됐는지 탐지 |
| `/release-notes` | 마일스톤 배포 내역 → 요약 이슈 + 배포 공지 메시지 |

### 개인 생산성 (선택 설치)

| 스킬 | 용도 |
|------|------|
| `/daily-note` | 일일 노트 생성 / 작업 로그 완성 |
| `/standup` | 데일리 스탠드업 자동 구성 |
| `/meeting-note` | 회의 내용 구조화 저장 |
| `/til` | TIL 정리 |
| `/weekly-retro` | 주간 KPT 회고 |
| `/weekly-meeting-update` | 주간회의록 초안 생성 |
| `/post-illustrate` | 블로그 글 이미지 매니페스트 생성 |

---

## 노트 시스템 설정 (개인 생산성 스킬 사용 시)

> **개인 생산성 스킬(`/daily-note`, `/standup` 등)을 쓰지 않는다면 이 섹션 전체를 건너뛰어도 된다.**

개인 생산성 스킬은 마크다운 파일을 저장할 노트 경로가 필요하다.
노트 시스템이 없으면 이 스킬들을 설치하지 않아도 된다.

### Obsidian 설치

[Obsidian](https://obsidian.md)은 로컬 마크다운 기반 노트 앱으로, 개인 스킬과 가장 잘 맞는다.

**macOS**
```bash
brew install --cask obsidian
# 또는 https://obsidian.md/download 에서 .dmg 다운로드
```

**Windows**
- https://obsidian.md/download → Windows Installer (.exe)

**Linux**
```bash
# Flatpak
flatpak install flathub md.obsidian.Obsidian

# 또는 공식 사이트에서 AppImage 다운로드
```

### Vault 생성 및 경로 확인

1. Obsidian 실행 → **Create new vault**
2. Vault 이름·위치 지정 (예: `~/Documents/Dev-Vault`)
3. 생성 완료 후 경로 메모

### 개인 스킬에 노트 경로 연결

`install.sh --personal` 실행 중 자동으로 경로를 묻고 설정한다.

```
개인 스킬 노트 경로 설정
Obsidian 등 마크다운 노트 저장 경로가 있으면 지금 바로 설정합니다.
(없으면 엔터 — 나중에 수동 설정 가능)
경로: /Users/<사용자명>/Documents/Dev-Vault
```

경로를 입력하면 `daily-note`, `standup`, `meeting-note`, `til`, `weekly-retro`, `weekly-meeting-update` 스킬의 `<개인_노트_경로>` 플레이스홀더를 자동으로 치환한다. 치환 완료 후 `/daily-note`, `/standup` 등 스킬을 바로 사용할 수 있다.

**설치 시 건너뛴 경우 — 수동 설정:**
```bash
NOTE_PATH="/Users/<사용자명>/Documents/Dev-Vault"  # Vault 경로로 교체

for skill in daily-note standup meeting-note til weekly-retro weekly-meeting-update; do
  FILE=~/.claude/skills/$skill/SKILL.md
  [ -f "$FILE" ] && sed -i.bak "s|<개인_노트_경로>|$NOTE_PATH|g" "$FILE" && rm -f "${FILE}.bak" && echo "✓ $skill"
done
```

**교체 여부 확인** (설치 후 동작이 이상하면):
```bash
grep -l "<개인_노트_경로>" ~/.claude/skills/*/SKILL.md 2>/dev/null
```
출력된 파일이 있으면 위 `sed` 명령으로 경로를 교체하지 않은 것이다.
