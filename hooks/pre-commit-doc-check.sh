#!/usr/bin/env bash
# PreToolUse:Bash 훅 — git commit 전 개발문서 (FE·BE) 존재 여부 확인
# exit 2 → Claude에게 경고 메시지 전달 (non-blocking)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null)

# git commit 명령이 아니면 통과
if ! echo "$COMMAND" | grep -qE "git commit"; then
  exit 0
fi

# 특수 케이스 통과 (amend, allow-empty, docs: 접두사 커밋)
if echo "$COMMAND" | grep -qE "git commit.*(--amend|--allow-empty)"; then
  exit 0
fi
if echo "$COMMAND" | grep -qE "git commit.*['\"]docs\s*:"; then
  exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

# develop / main 직접 커밋 방지 (S75, 비차단 경고)
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if echo "$CURRENT_BRANCH" | grep -qE "^(develop|main|master)$"; then
  echo "⚠️  [브랜치 경고] 현재 브랜치: $CURRENT_BRANCH"
  echo "     $CURRENT_BRANCH 에 직접 커밋하는 것은 팀 규칙에 어긋날 수 있습니다."
  echo "     작업 브랜치(task/<번호> 또는 fix/<번호>)로 전환 후 커밋하세요."
  exit 2
fi

# 커밋 메시지 이슈 번호 체크 (S74, 비차단 경고)
COMMIT_MSG_FILE=$(git rev-parse --git-dir 2>/dev/null)/COMMIT_EDITMSG
if [ -f "$COMMIT_MSG_FILE" ]; then
  COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
  if ! echo "$COMMIT_MSG" | grep -qE "#[0-9]+"; then
    echo "⚠️  [이슈번호 없음] 커밋 메시지에 이슈 번호(#번호)가 없습니다."
    echo "     예: feat: [FE] 기능 추가 #1234  /  fix: [BE] API 오류 수정 #1234"
    exit 2
  fi
fi

# ====================================================
# [프로젝트 설정] — 직접 수정하거나 .claude/hooks-config.sh 로 팀 공유
# 변수: FE_COMMIT_PATTERN, FE_DOMAIN_EXTRACT, FE_DOC_DIR_BASE (필수)
#       BE_COMMIT_PATTERN, BE_DOMAIN_EXTRACT, BE_DOC_DIR_BASE (BE·풀스택만)
# 팀 공유: 운영_가이드/팀_훅_설정_공유.md 참조
# ====================================================
FE_COMMIT_PATTERN="^(<소스경로1>|<소스경로2>)/.*\.(js|ts|tsx|jsx)$"
FE_DOMAIN_EXTRACT='s|<소스경로>/pages/([^/]+)/.*|\1|; s|<소스경로>/views/([^/]+)/.*|\1|'
FE_DOC_DIR_BASE="docs/<서비스명>/pages"
# BE_COMMIT_PATTERN="^(<BE소스경로>)/.*\.(py|go|java|kt|rs)$"
# BE_DOMAIN_EXTRACT='s|<BE소스경로>/routes/([^/]+)/.*|\1|; s|<BE소스경로>/services/([^/]+)/.*|\1|; s|<BE소스경로>/handlers/([^/]+)/.*|\1|; s|<BE소스경로>/models/([^/]+)/.*|\1|; s|<BE소스경로>/schemas/([^/]+)/.*|\1|'
# BE_DOC_DIR_BASE="docs/<BE서비스명>/pages"

# 팀 공유 설정 오버라이드 (.claude/hooks-config.sh 가 있으면 변수 덮어씀)
if REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  [ -f "$REPO_ROOT/.claude/hooks-config.sh" ] && source "$REPO_ROOT/.claude/hooks-config.sh"
fi

# 플레이스홀더 미교체 감지
if echo "$FE_COMMIT_PATTERN" | grep -q '<소스경로'; then
  echo "⚠️  [훅 미설정] pre-commit-doc-check.sh의 [프로젝트 설정] 변수가 아직 교체되지 않았습니다."
  echo "     방법 1: ~/.claude/hooks/pre-commit-doc-check.sh 의 변수 직접 수정"
  echo "     방법 2: 프로젝트 레포에 .claude/hooks-config.sh 생성 — 운영_가이드/팀_훅_설정_공유.md 참조"
  exit 2
fi

FE_FILES=$(echo "$STAGED" | grep -E "$FE_COMMIT_PATTERN" | grep -v "__tests__" | grep -v "\.test\." | grep -v "\.spec\.")

BE_FILES=""
if [ -n "${BE_COMMIT_PATTERN:-}" ]; then
  BE_FILES=$(echo "$STAGED" | grep -E "$BE_COMMIT_PATTERN" | grep -v "_test\." | grep -v "test_")
fi

MISSING_DOCS=""

# FE 파일 처리
for FILE in $FE_FILES; do
  DOMAIN=$(echo "$FILE" | sed -E "$FE_DOMAIN_EXTRACT")
  DOC_DIR="${FE_DOC_DIR_BASE}/${DOMAIN}"
  DOC_PREFIX="FE"

  if [ -d "$DOC_DIR" ]; then
    DOC_COUNT=$(find "$DOC_DIR" -name "${DOC_PREFIX}_*.md" 2>/dev/null | wc -l | tr -d ' ')
    STAGED_DOC=$(echo "$STAGED" | grep -E "^${DOC_DIR}/${DOC_PREFIX}_.*\.md$" | head -1)
    if [ "$DOC_COUNT" -eq 0 ] && [ -z "$STAGED_DOC" ]; then
      MISSING_DOCS="${MISSING_DOCS}\n  - ${DOC_DIR}/${DOC_PREFIX}_*.md (미존재)"
    elif [ -z "$STAGED_DOC" ] && [ "$DOC_COUNT" -gt 0 ]; then
      MISSING_DOCS="${MISSING_DOCS}\n  - ${DOC_DIR}/ 문서 갱신 여부 미확인"
    fi
  else
    STAGED_DOC=$(echo "$STAGED" | grep -E "^docs/.*${DOMAIN}.*/${DOC_PREFIX}_.*\.md$" | head -1)
    [ -z "$STAGED_DOC" ] && MISSING_DOCS="${MISSING_DOCS}\n  - ${DOC_DIR}/ (디렉토리 없음)"
  fi
done

# BE 파일 처리
for FILE in $BE_FILES; do
  DOMAIN=$(echo "$FILE" | sed -E "${BE_DOMAIN_EXTRACT:-}")
  DOC_DIR="${BE_DOC_DIR_BASE:-docs/pages}/${DOMAIN}"
  DOC_PREFIX="BE"

  if [ -d "$DOC_DIR" ]; then
    DOC_COUNT=$(find "$DOC_DIR" -name "${DOC_PREFIX}_*.md" 2>/dev/null | wc -l | tr -d ' ')
    STAGED_DOC=$(echo "$STAGED" | grep -E "^${DOC_DIR}/${DOC_PREFIX}_.*\.md$" | head -1)
    if [ "$DOC_COUNT" -eq 0 ] && [ -z "$STAGED_DOC" ]; then
      MISSING_DOCS="${MISSING_DOCS}\n  - ${DOC_DIR}/${DOC_PREFIX}_*.md (미존재)"
    elif [ -z "$STAGED_DOC" ] && [ "$DOC_COUNT" -gt 0 ]; then
      MISSING_DOCS="${MISSING_DOCS}\n  - ${DOC_DIR}/ 문서 갱신 여부 미확인"
    fi
  else
    STAGED_DOC=$(echo "$STAGED" | grep -E "^docs/.*${DOMAIN}.*/${DOC_PREFIX}_.*\.md$" | head -1)
    [ -z "$STAGED_DOC" ] && MISSING_DOCS="${MISSING_DOCS}\n  - ${DOC_DIR}/ (디렉토리 없음)"
  fi
done

if [ -z "$FE_FILES" ] && [ -z "$BE_FILES" ]; then
  exit 0
fi

if [ -n "$MISSING_DOCS" ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────────────┐"
  echo "│  ⚠️  개발문서 확인 필요 (FE_*.md · BE_*.md)              │"
  echo "├─────────────────────────────────────────────────────────┤"
  echo "│  커밋 전 아래 항목을 확인하세요:                           │"
  echo -e "│  ${MISSING_DOCS}                                       │"
  echo "├─────────────────────────────────────────────────────────┤"
  echo "│  1. 문서 신규 작성 또는 갱신                               │"
  echo "│  2. 사용자에게 문서 내용 공유 후 승인 받기                   │"
  echo "│  3. 문서를 같은 커밋 또는 별도 docs: 커밋으로 포함           │"
  echo "└─────────────────────────────────────────────────────────┘"
  echo ""
  exit 2
fi

exit 0
