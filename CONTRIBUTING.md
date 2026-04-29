---
tags: [하네스, 기여, 가이드]
updated: 2026-04-27
---

# 기여 가이드

## 스킬 수정

스킬을 수정할 때 **하네스 소스 폴더와 `~/.claude/skills/` 양쪽을 함께 갱신**한다.

```bash
# 로컬에서 수정 후 하네스 폴더로 동기화 (프로젝트 스킬)
cp ~/.claude/skills/<스킬명>/SKILL.md \
   하네스/skills/<스킬명>/SKILL.md

# 개인 생산성 스킬인 경우
cp ~/.claude/skills/<스킬명>/SKILL.md \
   하네스/personal-skills/<스킬명>/SKILL.md
```

| 위치 | 역할 |
|------|------|
| `하네스/skills/` | 프로젝트 스킬 소스 오브 트루스 |
| `하네스/personal-skills/` | 개인 스킬 소스 오브 트루스 |
| `~/.claude/skills/` | 실행 위치 — Claude Code가 실제로 읽는 곳 |

## 문서 수정

문서를 수정하면 파일 상단 frontmatter의 `updated` 날짜를 갱신하고 `CHANGELOG.md`에 기록한다.

```markdown
---
updated: YYYY-MM-DD   ← 오늘 날짜로 갱신
---
```

## CHANGELOG 기록 형식

```markdown
## YYYY-MM-DD (N차 — 변경 요약)

### 수정 — 파일명
- `경로/파일명` — 변경 내용 한 줄 요약
```

## 이슈 제보

버그·개선 요청은 GitHub Issues로 제보한다.

> **배포 전 필수**: 이 섹션에 실제 GitHub 레포 URL을 추가한다.
> 예: `https://github.com/<owner>/<repo>/issues`

- **버그**: 재현 방법 + 기대 동작 + 실제 동작 + 환경 정보 (OS, Claude Code 버전)
- **기능 요청**: 문제 상황 + 원하는 동작 + 대안 검토 여부

## 훅 스크립트 수정

훅을 수정하면 `hooks/` 소스 파일과 `Claude Code/훅_스크립트_전문.md` 코드블록을 함께 갱신한다.

```bash
# 로컬 훅 수정 후 하네스로 동기화
cp ~/.claude/hooks/check-source-doc.sh       하네스/hooks/check-source-doc.sh
cp ~/.claude/hooks/pre-commit-doc-check.sh   하네스/hooks/pre-commit-doc-check.sh
```
