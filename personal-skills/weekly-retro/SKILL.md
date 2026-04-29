---
name: weekly-retro
description: |
  이번 주 일일노트·TIL·git 커밋을 취합해 주간 회고를 자동 생성한다.
  KPT(Keep/Problem/Try) 형식으로 정리. 매주 금요일 또는 스프린트 종료 시 사용.
  트리거 키워드: "주간 회고", "회고 작성", "이번 주 회고", "/weekly-retro"
---

> ⚠️ **설치 후 필수**: 이 파일의 `<개인_노트_경로>`를 실제 노트 경로로 교체해야 정상 동작한다.
> 교체 방법: `README.md`의 "개인 스킬에 노트 경로 연결" 섹션 참조.

# Weekly Retro

이번 주 활동을 자동 취합해 KPT 회고로 구성한다.

## Step 1 — 이번 주 데이터 수집

```bash
# 노트 경로 설정 확인 — 미설정이면 중단
if echo "<개인_노트_경로>" | grep -q '<개인_노트_경로>'; then
  echo "⚠ [설정 필요] ~/.claude/skills/weekly-retro/SKILL.md 에서 <개인_노트_경로>를 실제 경로로 교체하세요."
  echo "  교체 후 스킬을 다시 실행해주세요. (참조: README.md '개인 스킬에 노트 경로 연결' 섹션)"
  exit 1
fi

# 이번 주 git 커밋 (월~오늘)
git log --oneline --since="last monday 00:00" \
  --author="$(git config user.name)" 2>/dev/null

# 이번 주 TIL 파일 목록
THIS_WEEK_START=$(date -v-mon +%Y-%m-%d 2>/dev/null || date -d "last monday" +%Y-%m-%d)
find <개인_노트_경로>/TIL \
  -name "*.md" -newer "<개인_노트_경로>/TIL" 2>/dev/null | sort

# 이번 주 일일노트 파일 목록
find <개인_노트_경로>/일일노트 \
  -name "*.md" | sort | tail -7
```

각 파일의 주요 항목을 읽어 주제별로 분류한다.

## Step 2 — KPT 구성

수집한 데이터를 아래 기준으로 분류한다.

| 항목 | 기준 |
|------|------|
| **Keep** | 잘 된 것, 계속할 것 — 완료한 기능·버그 수정, 좋은 패턴 발견 |
| **Problem** | 아쉬웠던 것 — 블로커, 예상보다 오래 걸린 작업, 반복 실수 |
| **Try** | 다음 주에 시도할 것 — Problem 해결책, 새로 배운 것 적용 |

## Step 3 — 회고 파일 생성

```markdown
---
tags: [회고, 주간회고]
date: YYYY-MM-DD
week: YYYY-WW
---

# 주간 회고 — YYYY년 MM월 W주차

## Keep (잘 된 것)
- 

## Problem (아쉬웠던 것)
- 

## Try (다음 주 시도)
- 

---

## 이번 주 완료 작업
<git 커밋 목록>

## 이번 주 TIL
<TIL 파일 링크 목록>
```

저장: `개인/회고/YYYY-MM-DD.md`

## Step 4 — 완료 보고

```
[Weekly Retro]
파일: 개인/회고/YYYY-MM-DD.md
커밋: N개 / TIL: N개 / 일일노트: N개 취합
```
