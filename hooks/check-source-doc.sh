#!/bin/bash
# Claude Code PostToolUse 훅 — 소스 파일 수정 시 FE_*.md 자동 감지 및 작성 유도
# stdin: {"tool_name": "Edit"|"Write", "tool_input": {"file_path": "..."}, ...}

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null || true)

if [[ -z "$FILE_PATH" ]]; then exit 0; fi

# 문서 파일 자체는 제외
if [[ "$FILE_PATH" =~ /docs/ ]] || [[ "$FILE_PATH" =~ \.md$ ]]; then exit 0; fi

# ====================================================
# [프로젝트 설정] — 직접 수정하거나 .claude/hooks-config.sh 로 팀 공유
# 변수: FE_PATTERN, FE_DOC_BASE, FE_PROJECT (필수)
#       BE_PATTERN, BE_DOC_BASE, BE_PROJECT (BE·풀스택만)
# 팀 공유: 운영_가이드/팀_훅_설정_공유.md 참조
# ====================================================
FE_PATTERN="<소스경로>/(pages|components|hooks|api)/([^/]+)/"
FE_DOC_BASE="docs/<서비스명>/pages"
FE_PROJECT="<서비스명>"
# BE_PATTERN="<BE소스경로>/(routes|services|handlers|models)/([^/]+)"
# BE_DOC_BASE="docs/<BE서비스명>/pages"
# BE_PROJECT="<BE서비스명>"

# 팀 공유 설정 오버라이드 (.claude/hooks-config.sh 가 있으면 변수 덮어씀)
if REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  [ -f "$REPO_ROOT/.claude/hooks-config.sh" ] && source "$REPO_ROOT/.claude/hooks-config.sh"
fi

# 플레이스홀더 미교체 감지
if [[ "$FE_PATTERN" == *'<소스경로>'* ]]; then
  echo "⚠️  [훅 미설정] check-source-doc.sh의 [프로젝트 설정] 변수가 아직 교체되지 않았습니다."
  echo "     방법 1: ~/.claude/hooks/check-source-doc.sh 의 FE_PATTERN, FE_DOC_BASE, FE_PROJECT 직접 수정"
  echo "     방법 2: 프로젝트 레포에 .claude/hooks-config.sh 생성 — 운영_가이드/팀_훅_설정_공유.md 참조"
  exit 2
fi

if [[ "$FILE_PATH" =~ $FE_PATTERN ]]; then
  DOMAIN="${BASH_REMATCH[2]}"
  DOC_BASE="$FE_DOC_BASE"
  PROJECT="$FE_PROJECT"
  DOC_PREFIX="FE"
elif [[ -n "${BE_PATTERN:-}" ]] && [[ "$FILE_PATH" =~ ${BE_PATTERN} ]]; then
  DOMAIN="${BASH_REMATCH[2]}"
  DOC_BASE="${BE_DOC_BASE:-docs/pages}"
  PROJECT="${BE_PROJECT:-unknown}"
  DOC_PREFIX="BE"
else
  exit 0
fi

REPO_ROOT="${REPO_ROOT:-$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC=$(find "$REPO_ROOT/$DOC_BASE" -name "${DOC_PREFIX}_*.md" -path "*/$DOMAIN/*" 2>/dev/null | head -1 || true)

if [[ -z "$DOC" ]]; then
  TEMPLATE_NOTE="FE_기능정리_템플릿.md"
  [ "$DOC_PREFIX" = "BE" ] && TEMPLATE_NOTE="BE_기능정리_템플릿.md"
  cat << EOF
⚠️  [${DOC_PREFIX} 문서 미존재] 소스 파일이 수정됐지만 해당 도메인의 ${DOC_PREFIX} 문서가 없습니다.

- 수정 파일 : $FILE_PATH
- 도메인    : $DOMAIN ($PROJECT)
- 예상 경로 : $REPO_ROOT/$DOC_BASE/$DOMAIN/${DOC_PREFIX}_$(echo "$DOMAIN" | tr '[:lower:]' '[:upper:]' | tr '-' '_').md

\`하네스/Claude Code/템플릿/${TEMPLATE_NOTE}\` 기반으로 ${DOC_PREFIX}_*.md를 지금 바로 작성해주세요.
EOF
else
  RELATIVE_DOC="${DOC#$REPO_ROOT/}"
  echo "📄 [${DOC_PREFIX} 문서 확인] $RELATIVE_DOC — 수정 내용에 맞게 신선도 날짜와 작성 이력을 갱신해주세요."
fi
