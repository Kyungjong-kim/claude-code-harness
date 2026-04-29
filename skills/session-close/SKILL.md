---
name: session-close
description: |
  세션 종료 시 작업 내용을 문서에 정리한다. HANDOFF 구조가 있으면 3종 갱신,
  없으면 변경 요약만 출력한다. 어느 프로젝트에서나 사용 가능.
  트리거 키워드: "세션 종료", "마무리 해줘", "문서 갱신", "/session-close"
---

# Session Close

세션에서 변경한 내용을 문서로 정리하고 다음 작업을 기록한다.

## Step 1 — 변경 내용 수집

```bash
# 이번 세션 변경 파일
git diff --name-only HEAD 2>/dev/null
git status --short 2>/dev/null

# 오늘 커밋
git log --oneline --since="today 00:00" 2>/dev/null
```

## Step 2 — HANDOFF 구조 감지

아래 경로 중 존재하는 것 확인:

```bash
find . -name "HANDOFF_NOW.md" -not -path "*/node_modules/*" 2>/dev/null | head -3
```

| 결과 | 처리 |
|------|------|
| HANDOFF_NOW.md 있음 | Step 3-A 실행 (HANDOFF 3종 갱신) |
| 없음 | Step 3-B 실행 (변경 요약만 출력) |

---

## Step 3-A — HANDOFF 3종 갱신 (HANDOFF 구조 있는 경우)

CLAUDE.md에서 갱신 순서·경로 확인 후 아래 순서로 갱신한다.

**① 기능 정리 문서 갱신 여부 확인 (코드 변경이 있는 경우)**

```bash
# 이번 세션에서 수정된 소스 파일의 도메인 목록
git diff --name-only HEAD 2>/dev/null | grep -E "\.(ts|tsx|js|jsx|py|go|java|kt|rs)$" | \
  grep -v "\.test\.\|\.spec\.\|_test\." | head -10
```

수정된 소스 파일이 있으면 아래를 확인한다:
- **FE 소스 변경**: 해당 도메인의 `FE_*.md`가 이번 세션 내 갱신됐는지 확인
- **BE 소스 변경**: 해당 도메인의 `BE_*.md`가 이번 세션 내 갱신됐는지 확인
- 갱신되지 않았으면 HANDOFF 갱신 전에 먼저 기능 정리 문서를 갱신한다.
- 문서가 없으면 템플릿 기반으로 신규 작성 후 진행한다.

---

**② HANDOFF_NOW.md**
- §1 현재 상태: 브랜치·이슈·빌드 명령 갱신
- §1 "이번 세션 완료 (YYYY-MM-DD)": 세션 날짜와 완료 작업 요약으로 갱신 (날짜·이슈번호·변경 내용 1~2줄)
- §2 다음 작업: 완료 항목 삭제, 새 할 일 추가, 우선순위 재정렬
- **2주 미착수 항목 감지**: §2 항목 중 `YYYY-MM-DD` 형식 날짜가 포함된 항목이 있으면 오늘 날짜와 비교해 14일 초과 항목에 `⏸` 태그 추가 후 §2 하단으로 이동
- 60줄 이하 유지 (초과 시 하위 항목을 HANDOFF.md로 이관)

갱신 후 줄 수 확인:
```bash
HANDOFF_PATH=$(find . -name "HANDOFF_NOW.md" -not -path "*/node_modules/*" 2>/dev/null | head -1)
LINE_COUNT=$(wc -l < "$HANDOFF_PATH" 2>/dev/null | tr -d ' ')
if [ "${LINE_COUNT:-0}" -gt 60 ]; then
  echo "⚠ HANDOFF_NOW.md가 ${LINE_COUNT}줄입니다 (60줄 초과). §2 하위 항목을 HANDOFF.md로 이관하세요."
fi
```

**③ 세션_노트.md (또는 동등한 파일)**
- 파일이 **없으면 먼저 생성** (Write 도구로 빈 파일 생성)
- 최상단에 prepend:
  ```
  > Session note YYYY-MM-DD: [변경 내용 1~2줄. 다음 연결점]
  ```
- 30일 이상 지난 항목은 `history/HANDOFF_archive_YYYY.md`로 이관 (월별 갱신)

**④ HANDOFF.md**
- 최상단에 새 섹션 추가:
  ```markdown
  ## Session Update YYYY-MM-DD

  ### 변경 파일
  - `<경로>` — <변경 내용 한줄>

  ### 주요 변경
  - <변경 1>

  ### 다음 할 일
  - [ ] <미완료 작업>
  ```

---

## Step 3-B — 변경 요약 출력 (HANDOFF 없는 경우)

```
[세션 요약] YYYY-MM-DD
변경 파일: N개
- <파일> — <변경 내용>

주요 변경:
- <변경 1>

다음 할 일:
- <미완료 항목>
```

---

## Step 4 — 완료 보고

```
[Session Close]
갱신 문서: HANDOFF_NOW.md / 세션_노트.md / HANDOFF.md  ← HANDOFF 있는 경우
변경 파일: N개
다음 작업: <HANDOFF §2 첫 항목>
```
