#!/bin/bash
# Claude Code 하네스 부트스트랩
# 이 스크립트가 있는 하네스/ 폴더를 기준으로 스킬·설정을 설치한다.
#
# 사용법:
#   bash 하네스/install.sh                      # 전역 설치 (~/.claude/skills/)
#   bash 하네스/install.sh --local              # 프로젝트 로컬 설치 (.claude/skills/)
#   bash 하네스/install.sh --personal          # 개인 생산성 스킬 함께 설치
#   bash 하네스/install.sh --hooks             # 훅 스크립트 설치 (~/.claude/hooks/)
#   bash 하네스/install.sh --dir /추가할/경로  # additionalDirectories 지정
#   bash 하네스/install.sh --personal --dir /경로
#   bash 하네스/install.sh --hooks --personal  # 훅 + 개인 스킬 동시 설치
#
# --local 모드:
#   .claude/skills/ 에 스킬을 설치한다. git 추적 시 팀 전체에 공유된다.
#   install.sh 없이도 팀원이 git clone 후 바로 스킬을 사용할 수 있다.
#   훅 스크립트는 여전히 전역(~/.claude/hooks/)에 수동 설치 필요.
#
# --hooks 모드 (FE/BE/풀스택 프로젝트):
#   check-source-doc.sh + pre-commit-doc-check.sh 를 ~/.claude/hooks/ 에 복사하고
#   settings.json hooks 섹션을 자동 등록한다.
#   ※ 훅은 --local 모드와 관계없이 항상 전역(~/.claude/hooks/)에 설치됩니다.
#   설치 후 /project-init 실행 시 소스 경로를 자동 분석해 .claude/hooks-config.sh 를 생성한다.

set -e

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_VERSION=$(cat "$HARNESS_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "unknown")
SKILLS_SRC="$HARNESS_DIR/skills"
PERSONAL_SRC="$HARNESS_DIR/personal-skills"
SKILLS_DST="$HOME/.claude/skills"
SETTINGS="$HOME/.claude/settings.json"
EXTRA_DIR=""
INSTALL_PERSONAL=""
LOCAL_INSTALL=""
INSTALL_HOOKS=""
FORCE_INSTALL=""
PYTHON3_OK=true

# 인자 파싱
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) EXTRA_DIR="$2"; shift 2 ;;
    --personal) INSTALL_PERSONAL="yes"; shift ;;
    --local) LOCAL_INSTALL="yes"; shift ;;
    --hooks) INSTALL_HOOKS="yes"; shift ;;
    --force) FORCE_INSTALL="yes"; shift ;;
    *) shift ;;
  esac
done

# 로컬 설치 모드: 경로를 현재 디렉터리 기준으로 전환
if [ "$LOCAL_INSTALL" = "yes" ]; then
  SKILLS_DST="$(pwd)/.claude/skills"
  SETTINGS="$(pwd)/.claude/settings.json"
fi

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Claude Code 하네스 부트스트랩       ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "하네스 버전: $HARNESS_VERSION"
echo "하네스 경로: $HARNESS_DIR"
echo "스킬 대상:   $SKILLS_DST"
if [ "$LOCAL_INSTALL" = "yes" ]; then
  echo "모드:        프로젝트 로컬 (.claude/skills/)"
else
  echo "모드:        전역 (~/.claude/skills/)"
fi
echo ""

# ── 의존성 확인 ──────────────────────────────────────────────
echo "[1/5] 의존성 확인"
HARD_OK=true
for cmd in claude git; do
  if command -v "$cmd" &>/dev/null; then
    if [ "$cmd" = "claude" ]; then
      CLAUDE_VER=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0.0")
      CLAUDE_MAJOR=$(echo "$CLAUDE_VER" | cut -d. -f1)
      if [ "${CLAUDE_MAJOR:-0}" -lt 1 ] 2>/dev/null; then
        echo "  ⚠ claude $CLAUDE_VER — 1.x 이상 권장: npm update -g @anthropic-ai/claude-code"
      else
        echo "  ✓ claude $CLAUDE_VER"
      fi
    else
      echo "  ✓ $cmd"
    fi
  else
    echo "  ✗ $cmd — 설치 필요 (필수)"
    HARD_OK=false
  fi
done
if command -v python3 &>/dev/null; then
  echo "  ✓ python3"
else
  echo "  ⚠ python3 없음 — settings.json 자동 설정 불가 (스킬·훅 설치는 계속 진행)"
  PYTHON3_OK=false
fi
if command -v gh &>/dev/null; then
  echo "  ✓ gh (GitHub CLI)"
else
  echo "  ⚠ gh 없음 — project-fix / project-pr / project-issue 스킬 사용 불가"
fi
if [ "$HARD_OK" = false ]; then
  echo ""
  echo "  필수 의존성이 없습니다. 아래 명령으로 설치 후 다시 실행하세요."
  echo ""
  echo "    claude 없음  →  npm install -g @anthropic-ai/claude-code"
  echo "                    (Node.js 18 이상 필요: https://nodejs.org)"
  echo "    git 없음     →  https://git-scm.com/downloads"
  exit 1
fi
echo ""

# ── 스킬 복사 (프로젝트 워크플로우) ─────────────────────────
echo "[2/5] 프로젝트 스킬 복사"
if [ ! -d "$SKILLS_SRC" ]; then
  echo "  오류: skills/ 폴더 없음 — $SKILLS_SRC"
  exit 1
fi

# 쓰기 권한 사전 확인 (mkdir 실패 전에 명확한 안내 제공)
_PERM_CHECK="$SKILLS_DST"
while [ ! -d "$_PERM_CHECK" ] && [ "$_PERM_CHECK" != "/" ]; do
  _PERM_CHECK=$(dirname "$_PERM_CHECK")
done
if [ ! -w "$_PERM_CHECK" ]; then
  echo "  ✗ 쓰기 권한 없음: $_PERM_CHECK"
  echo "     해결: sudo chown \$(whoami) \"$_PERM_CHECK\"  또는  chmod u+w \"$_PERM_CHECK\""
  exit 1
fi
mkdir -p "$SKILLS_DST"
COPIED=0
SKIPPED=0
for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_dir")
  dst="$SKILLS_DST/$skill_name"
  if [ -d "$dst" ] && [ -z "$FORCE_INSTALL" ]; then
    echo "  스킵 (이미 존재): $skill_name  ← --force 로 덮어쓰기 가능"
    SKIPPED=$((SKIPPED + 1))
  else
    [ -d "$dst" ] && rm -rf "$dst"
    cp -r "$skill_dir" "$dst"
    [ -n "$FORCE_INSTALL" ] && [ "$SKIPPED" -eq 0 ] && echo "  ↺ 덮어쓰기: $skill_name" || echo "  ✓ $skill_name"
    COPIED=$((COPIED + 1))
  fi
done
echo "  → 복사·갱신 ${COPIED}개 / 스킵 ${SKIPPED}개"
echo ""

# ── 개인 생산성 스킬 복사 (옵션) ────────────────────────────
echo "[3/5] 개인 생산성 스킬"
if [ -z "$INSTALL_PERSONAL" ]; then
  echo "  daily-note, standup, meeting-note, til, weekly-retro, weekly-meeting-update"
  echo "  Obsidian 등 개인 노트·일일 루틴이 있으면 y, 없으면 N"
  echo "  (나중에 --personal 플래그로 재설치 가능)"
  read -r -p "  설치할까요? (y/N): " PERSONAL_ANSWER
  case "$PERSONAL_ANSWER" in
    [yY]|[yY][eE][sS]) INSTALL_PERSONAL="yes" ;;
    *) INSTALL_PERSONAL="no" ;;
  esac
fi

if [ "$INSTALL_PERSONAL" = "yes" ]; then
  if [ ! -d "$PERSONAL_SRC" ]; then
    echo "  ⚠ personal-skills/ 폴더 없음 — 건너뜀"
  else
    COPIED_P=0
    SKIPPED_P=0
    for skill_dir in "$PERSONAL_SRC"/*/; do
      skill_name=$(basename "$skill_dir")
      dst="$SKILLS_DST/$skill_name"
      if [ -d "$dst" ]; then
        echo "  스킵 (이미 존재): $skill_name"
        SKIPPED_P=$((SKIPPED_P + 1))
      else
        cp -r "$skill_dir" "$dst"
        echo "  ✓ $skill_name"
        COPIED_P=$((COPIED_P + 1))
      fi
    done
    echo "  → 복사 ${COPIED_P}개 / 스킵 ${SKIPPED_P}개"
    echo ""
    echo "  개인 스킬 노트 경로 설정"
    echo "  Obsidian 등 마크다운 노트 저장 경로가 있으면 지금 바로 설정합니다."
    echo "  (없으면 엔터 — 나중에 수동 설정 가능)"
    read -r -p "  경로: " AUTO_NOTE_PATH
    if [ -n "$AUTO_NOTE_PATH" ]; then
      REPLACED_N=0
      for skill_dir in "$SKILLS_DST"/*/; do
        [ -d "$skill_dir" ] || continue
        skill=$(basename "$skill_dir")
        FILE="$skill_dir/SKILL.md"
        if [ -f "$FILE" ] && grep -q "<개인_노트_경로>" "$FILE"; then
          sed -i.bak "s|<개인_노트_경로>|$AUTO_NOTE_PATH|g" "$FILE" && rm -f "${FILE}.bak"
          echo "  ✓ $skill"
          REPLACED_N=$((REPLACED_N + 1))
        fi
      done
      echo "  → $REPLACED_N개 스킬 노트 경로 설정 완료: $AUTO_NOTE_PATH"
    else
      echo "  건너뜀 — 나중에 설정이 필요하면:"
      echo '     NOTE_PATH="/실제/노트/경로"'
      echo '     for skill_dir in ~/.claude/skills/*/; do'
      echo '       FILE="${skill_dir}SKILL.md"'
      echo '       [ -f "$FILE" ] && grep -q "<개인_노트_경로>" "$FILE" && \'
      echo '         sed -i.bak "s|<개인_노트_경로>|$NOTE_PATH|g" "$FILE" && rm -f "${FILE}.bak" && echo "✓ $(basename $skill_dir)"'
      echo '     done'
    fi
  fi
else
  echo "  건너뜀 — 필요하면 --personal 플래그로 재실행하세요."
fi
echo ""

# ── settings.json 설정 ───────────────────────────────────────
echo "[4/5] settings.json 설정"
if [ "$PYTHON3_OK" = false ]; then
  echo "  ⚠ python3 없음 — settings.json 자동 설정 건너뜀"
  echo "     수동 설정이 필요합니다. 참조: 하네스/설정_템플릿/settings.json_템플릿.md"
  echo ""
else

if [ "$LOCAL_INSTALL" = "yes" ]; then
  # 로컬 모드: .claude/settings.json 에 harness 경로만 추가 (model·hooks는 전역 유지)
  mkdir -p "$(pwd)/.claude"
  python3 - "$SETTINGS" "$HARNESS_DIR" << 'PYEOF'
import json, pathlib, shutil, sys

settings_path = pathlib.Path(sys.argv[1])
harness_dir = sys.argv[2].strip()

data = {}
if settings_path.exists():
    try:
        data = json.loads(settings_path.read_text())
    except json.JSONDecodeError:
        bak = str(settings_path) + ".bak"
        shutil.copy2(str(settings_path), bak)
        print(f"  ⚠ settings.json 파싱 실패 — {bak} 으로 백업 후 새로 생성")

# additionalDirectories (로컬 모드: harness 경로만)
data.setdefault("permissions", {}).setdefault("additionalDirectories", [])
dirs = data["permissions"]["additionalDirectories"]

if harness_dir and harness_dir not in dirs:
    dirs.append(harness_dir)
    print(f"  additionalDirectories 추가: {harness_dir}")

settings_path.write_text(json.dumps(data, indent=2, ensure_ascii=False))
print(f"  저장: {settings_path}")
PYEOF

  echo ""
  # .gitignore 실제 체크
  if [ -f ".gitignore" ] && grep -qE "^/?\.claude" ".gitignore" 2>/dev/null; then
    echo "  ⚠ .gitignore에 .claude/ 패턴 발견 — 팀 공유 시 이 줄을 제외해야 합니다:"
    grep -nE "^/?\.claude" ".gitignore" | head -3 | sed 's/^/     .gitignore:/'
  fi
  echo "  ⚠ 로컬 설치 후 추가 설정:"
  echo "     - .claude/settings.json 을 git 추적 대상에 포함하면 팀원도 harness 경로 자동 적용"
  echo "     - .claude/skills/ 도 git 추적 시 팀원이 install.sh 없이 스킬 사용 가능"
  echo "     - .gitignore 에서 .claude/ 제외 여부 확인"
  echo "     - 훅 스크립트(check-source-doc.sh 등)는 각자 전역 설치 필요: bash 하네스/install.sh"

else
  # 전역 모드: 기존 동작 유지
  # additionalDirectories 대화형 수집 (--dir 없을 때)
  if [ -z "$EXTRA_DIR" ]; then
    echo "  Claude Code가 프로젝트 외부에서 접근할 디렉터리가 있나요?"
    echo "  (예: Obsidian Vault 경로 / 없으면 엔터)"
    read -r -p "  경로: " EXTRA_DIR
  fi

  mkdir -p "$HOME/.claude"
  python3 - "$SETTINGS" "$EXTRA_DIR" "$HARNESS_DIR" << 'PYEOF'
import json, pathlib, shutil, sys

settings_path = pathlib.Path(sys.argv[1])
extra_dir = sys.argv[2].strip()
if extra_dir and not pathlib.Path(extra_dir).exists():
    print(f"  ⚠ 경로가 존재하지 않습니다: {extra_dir}")
    print(f"     additionalDirectories에 추가하지 않습니다. 올바른 절대 경로를 지정하세요.")
    extra_dir = ""
harness_dir = sys.argv[3].strip()

data = {}
if settings_path.exists():
    try:
        data = json.loads(settings_path.read_text())
    except json.JSONDecodeError:
        bak = str(settings_path) + ".bak"
        shutil.copy2(str(settings_path), bak)
        print(f"  ⚠ settings.json 파싱 실패 — {bak} 으로 백업 후 새로 생성")

# model 기본값
if "model" not in data:
    data["model"] = "claude-sonnet-4-6"
    print("  model: claude-sonnet-4-6 설정")
else:
    print(f"  model: {data['model']} (기존 유지)")

# additionalDirectories
data.setdefault("permissions", {}).setdefault("additionalDirectories", [])
dirs = data["permissions"]["additionalDirectories"]

for d in [extra_dir, harness_dir]:
    if d and d not in dirs:
        dirs.append(d)
        print(f"  additionalDirectories 추가: {d}")

settings_path.write_text(json.dumps(data, indent=2, ensure_ascii=False))
print(f"  저장: {settings_path}")
PYEOF

fi
fi  # python3 사용 가능 블록 끝

# ── 훅 스크립트 설치 (--hooks 플래그 또는 대화형 선택) ──────
echo "[5/5] 훅 스크립트 (FE/BE/풀스택)"
if [ -z "$INSTALL_HOOKS" ] && [ "$LOCAL_INSTALL" != "yes" ]; then
  echo "  check-source-doc.sh + pre-commit-doc-check.sh 를 ~/.claude/hooks/ 에 설치합니다."
  echo "  소스 수정 시 FE_*.md(FE) 또는 BE_*.md(BE) 문서 존재 여부 자동 확인"
  echo "  문서 훅이 불필요하면 건너뛰어도 됩니다."
  echo "  (나중에 --hooks 플래그로 재실행 가능)"
  read -r -p "  설치할까요? (y/N): " HOOKS_ANSWER
  case "$HOOKS_ANSWER" in
    [yY]|[yY][eE][sS]) INSTALL_HOOKS="yes" ;;
    *) INSTALL_HOOKS="no" ;;
  esac
fi

HOOKS_SRC="$HARNESS_DIR/hooks"
HOOKS_DST="$HOME/.claude/hooks"

if [ "$INSTALL_HOOKS" = "yes" ]; then
  if [ ! -d "$HOOKS_SRC" ]; then
    echo "  오류: hooks/ 폴더 없음 — $HOOKS_SRC"
  else
    mkdir -p "$HOOKS_DST"
    HOOKS_COPIED=0
    HOOKS_SKIPPED=0
    for hook_file in "$HOOKS_SRC"/*.sh; do
      hook_name=$(basename "$hook_file")
      dst_file="$HOOKS_DST/$hook_name"
      if [ -f "$dst_file" ] && [ -z "$FORCE_INSTALL" ]; then
        chmod +x "$dst_file"   # 권한 보장 (silent)
        echo "  스킵 (이미 존재): $hook_name — --force 로 덮어쓰기 가능"
        HOOKS_SKIPPED=$((HOOKS_SKIPPED + 1))
      else
        cp "$hook_file" "$dst_file"
        chmod +x "$dst_file"
        [ -n "$FORCE_INSTALL" ] && echo "  ↺ 덮어쓰기: $hook_name" || echo "  ✓ $hook_name"
        HOOKS_COPIED=$((HOOKS_COPIED + 1))
      fi
    done
    echo "  → 복사 ${HOOKS_COPIED}개 / 스킵 ${HOOKS_SKIPPED}개"
    echo "  ℹ 훅 스크립트는 git 명령을 내부적으로 사용합니다. git이 설치돼 있어야 정상 동작합니다."

    # settings.json hooks 섹션 자동 등록
    python3 - "$SETTINGS" << 'PYEOF'
import json, pathlib, shutil, sys

settings_path = pathlib.Path(sys.argv[1])
data = {}
if settings_path.exists():
    try:
        data = json.loads(settings_path.read_text())
    except json.JSONDecodeError:
        bak = str(settings_path) + ".bak"
        shutil.copy2(str(settings_path), bak)
        print(f"  ⚠ settings.json 파싱 실패 — {bak} 으로 백업. hooks 섹션 수동 등록 필요")
        sys.exit(0)

hooks = data.setdefault("hooks", {})

pre = hooks.setdefault("PreToolUse", [])
bash_hook = {"matcher": "Bash", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/pre-commit-doc-check.sh"}]}
if not any(h.get("matcher") == "Bash" and any("pre-commit-doc-check" in c.get("command","") for c in h.get("hooks",[])) for h in pre):
    pre.append(bash_hook)
    print("  hooks.PreToolUse (Bash) 등록 완료")
else:
    print("  hooks.PreToolUse (Bash) — 이미 등록됨")

post = hooks.setdefault("PostToolUse", [])
edit_hook = {"matcher": "Edit|Write", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/check-source-doc.sh"}]}
if not any(h.get("matcher") == "Edit|Write" and any("check-source-doc" in c.get("command","") for c in h.get("hooks",[])) for h in post):
    post.append(edit_hook)
    print("  hooks.PostToolUse (Edit|Write) 등록 완료")
else:
    print("  hooks.PostToolUse (Edit|Write) — 이미 등록됨")

settings_path.write_text(json.dumps(data, indent=2, ensure_ascii=False))
PYEOF

    echo ""
    echo "  ✔ 훅 설치 완료."
    echo "     프로젝트에서 /project-init 실행 시 소스 경로를 자동 분석해"
    echo "     .claude/hooks-config.sh 를 생성합니다 (별도 수동 설정 불필요)."
    echo "     수동 조정이 필요하면: 하네스/Claude Code/훅_스크립트_전문.md 참조"
    echo ""
    echo "  ✔ 설치 후 동작 확인:"
    echo "     소스 파일 하나를 수정하면 아래 메시지 중 하나가 출력되어야 합니다:"
    echo "       ⚠️  [문서 미존재] ...  또는  📄 [문서 확인] ..."
    echo "     메시지가 없으면 .claude/hooks-config.sh 의 소스 경로 패턴을 재확인하세요."
  fi
else
  if [ "$LOCAL_INSTALL" = "yes" ]; then
    echo "  로컬 모드: 훅은 전역(~/.claude/hooks/)에만 설치됩니다."
    echo "  훅이 필요하면: bash 하네스/install.sh --hooks"
  else
    echo "  건너뜀 — 필요하면 --hooks 플래그로 재실행하세요."
  fi
fi
echo ""

echo ""
echo "══════════════════════════════════════"
echo "  부트스트랩 완료"
echo ""
echo "  설치된 스킬:"
ls "$SKILLS_DST" | sed 's/^/    - /'
echo ""
echo "  설치 검증:"
if [ "$LOCAL_INSTALL" = "yes" ]; then
  echo "    ls .claude/skills/ | grep -E 'project-init|session-close'"
  if command -v python3 &>/dev/null; then
    echo "    python3 -c \"import json,pathlib; d=json.loads(pathlib.Path('.claude/settings.json').read_text()); print('harness dirs:', d.get('permissions',{}).get('additionalDirectories',[]))\""
  fi
else
  echo "    ls ~/.claude/skills/ | grep -E 'project-init|session-close'"
  if command -v python3 &>/dev/null; then
    echo "    python3 -c \"import json,pathlib; d=json.loads(pathlib.Path('~/.claude/settings.json').expanduser().read_text()); print('model:', d.get('model','(없음)'))\""
  fi
fi
echo ""
if [ "$LOCAL_INSTALL" = "yes" ]; then
  echo "  다음 단계:"
  echo "    1. git add .claude/ && git commit  # 팀 공유 시"
  echo "    2. claude 실행"
  echo "    3. /project-init 입력"
  echo ""
  echo "  ℹ  전역 스킬·훅이 필요하면: bash 하네스/install.sh"
else
  echo "  다음 단계:"
  echo "    1. GitHub CLI 인증 (project-fix · project-pr · project-issue 사용 시 필수)"
  echo "       gh auth login   # 브라우저 인증 또는 Personal Access Token 입력"
  echo "       gh auth status  # 인증 확인"
  echo "    2. 프로젝트 디렉터리로 이동"
  echo "    3. claude 실행"
  echo "    4. /project-init 입력"
fi
echo "══════════════════════════════════════"
echo ""
