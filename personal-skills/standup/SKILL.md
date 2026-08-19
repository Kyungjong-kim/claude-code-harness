---
name: standup
description: |
  데일리 스탠드업 노트를 자동 생성한다.
  어제 git 커밋 기반으로 "어제 한 일"을 채우고, 오늘 일일노트의 할 일·블로커를 연결한다.
  트리거 키워드: "스탠드업", "standup", "데일리", "/standup"
---

> ⚠️ **설치 후 필수**: 이 파일의 `<개인_노트_경로>`를 실제 노트 경로로 교체해야 정상 동작한다.
> 교체 방법: `README.md`의 "개인 스킬에 노트 경로 연결" 섹션 참조.

# Standup

데일리 스탠드업 3항목(어제/오늘/블로커)을 자동으로 구성한다.

## Step 1 — 어제 작업 수집

```bash
# 어제 커밋 목록
git log --oneline --after="yesterday 00:00" --before="today 00:00" \
  --author="$(git config user.name)" 2>/dev/null

# 어제 일일노트에서 "내일로 넘기는 것" 섹션 읽기
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
cat "<개인_노트_경로>/개인/일일노트/${YESTERDAY}.md" 2>/dev/null
```

## Step 2 — 오늘 할 일 수집

```bash
TODAY=$(date +%Y-%m-%d)
cat "<개인_노트_경로>/개인/일일노트/${TODAY}.md" 2>/dev/null
```

오늘 일일노트가 없으면 HANDOFF_NOW.md §2에서 다음 작업 읽기:
```bash
find . -name "HANDOFF_NOW.md" -not -path "*/node_modules/*" 2>/dev/null | head -1 | xargs grep -A 10 "§2\|다음 작업" 2>/dev/null
```

## Step 3 — 블로커 확인

사용자에게 질문:
> "블로커나 도움이 필요한 사항이 있나요? (없으면 엔터)"

## Step 4 — 스탠드업 노트 생성

```markdown
---
tags: [스탠드업]
date: YYYY-MM-DD
---

# 스탠드업 — YYYY-MM-DD

## 어제 한 일
- <git 커밋 또는 일일노트 완료 항목>

## 오늘 할 일
- <일일노트 할 일 또는 HANDOFF §2 항목>

## 블로커
- <없으면 "없음">
```

저장: `개인/스탠드업/YYYY-MM-DD.md`

## Step 5 — 슬랙/메시지 포맷 출력 (선택)

사용자가 "슬랙 포맷으로"라고 하면 아래 형식도 함께 출력:

```
[어제]
• <항목>

[오늘]
• <항목>

[블로커]
• <없으면 없음>
```
