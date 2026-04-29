---
name: project-pr
description: |
  현재 브랜치 기반으로 GitHub PR을 생성한다. 이슈 연결·Co-Authored-By 자동 포함.
  어느 GitHub 프로젝트에서나 사용 가능.
  트리거 키워드: "PR 만들어줘", "PR 생성", "풀리퀘스트", "/project-pr"
---

# Project PR

현재 브랜치의 변경사항으로 PR을 생성한다.

## Step 0 — 사전 확인 (git 레포 · 인증 · PR 중복)

```bash
# git 레포 확인 (S73)
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "⚠ 현재 디렉터리가 git 저장소가 아닙니다. 프로젝트 루트로 이동 후 다시 실행하세요."
  exit 1
fi

# 인증 확인 — 토큰 만료 vs 미로그인 분기 (S80)
AUTH_OUTPUT=$(gh auth status 2>&1)
if echo "$AUTH_OUTPUT" | grep -qi "not logged"; then
  echo "⚠ GitHub CLI 미인증 — gh auth login 후 재실행"
  exit 1
elif echo "$AUTH_OUTPUT" | grep -qi "expired\|token\|invalid"; then
  echo "⚠ GitHub CLI 토큰 만료 — gh auth refresh 실행 후 재실행"
  exit 1
fi

# 현재 브랜치 및 base 브랜치 감지
CURRENT_BRANCH=$(git branch --show-current)
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
BASE_BRANCH="${DEFAULT_BRANCH:-develop}"

# CLAUDE.md에 base 브랜치 규칙이 있으면 그것을 우선 사용
grep -iE "base.*브랜치|PR.*base|develop|main" CLAUDE.md 2>/dev/null | head -3

echo "현재 브랜치: $CURRENT_BRANCH / base 브랜치: $BASE_BRANCH"

# 원격 upstream 존재 여부 확인 (S33)
if ! git rev-parse --abbrev-ref "@{upstream}" > /dev/null 2>&1; then
  echo "⚠ 원격 브랜치가 없습니다. 먼저 push하세요:"
  echo "  git push -u origin $CURRENT_BRANCH"
  exit 1
fi

# 현재 브랜치에 이미 PR이 있는지 확인
gh pr list --head "$CURRENT_BRANCH" --json number,url,state 2>/dev/null
```

| 결과 | 처리 |
|------|------|
| git 레포 아님 | 안내 후 중단 |
| `⚠ 미인증` | `gh auth login` 안내 후 중단 |
| `⚠ 토큰 만료` | `gh auth refresh` 안내 후 중단 |
| 원격 브랜치 없음 | `git push -u origin <브랜치>` 안내 후 중단 |
| `현재 브랜치 == base 브랜치` | "작업 브랜치에서 실행해야 합니다. 현재 브랜치가 base 브랜치입니다." 안내 후 중단 |
| PR 목록에 항목 있음 | 기존 PR URL 출력 후 중단: "이미 PR이 존재합니다 — push만 하면 자동 반영됩니다." |
| PR 없음 | Step 1으로 진행 |

## Step 1 — 컨텍스트 수집

```bash
# 현재 브랜치 및 base 브랜치 감지
git branch --show-current
git log --oneline origin/HEAD..HEAD 2>/dev/null || git log --oneline -10

# 변경 내용 요약
git diff origin/HEAD...HEAD --stat 2>/dev/null || git diff --stat HEAD~1

# 브랜치명에서 이슈 번호 추출 (예: fix/1234 → #1234)
git branch --show-current | grep -oE '[0-9]+'
```

CLAUDE.md에서 base 브랜치·PR 규칙 확인:
```bash
grep -i "PR\|base\|develop\|main" CLAUDE.md 2>/dev/null | head -5
```

## Step 2 — PR 정보 구성

| 항목 | 결정 방법 |
|------|----------|
| base 브랜치 | CLAUDE.md 규칙 → 없으면 `main` or `develop` (remote에서 감지) |
| 제목 | 커밋 메시지 or 사용자 입력 |
| 이슈 연결 | 브랜치명 번호 추출 → `Closes #번호` |
| Co-Authored-By | 항상 포함 |

**base 브랜치 사용자 확인 (S34):** 감지한 base 브랜치를 PR 생성 전에 명시하고 확인받는다.
> "PR base 브랜치: `<감지된 브랜치>` — 맞나요? (아니면 올바른 브랜치명 입력)"

이슈 번호를 감지하지 못한 경우 사용자에게 질문:
> "연결할 이슈 번호가 있나요?"

## Step 3 — PR 생성

```bash
gh pr create \
  --title "<제목>" \
  --base <base브랜치> \
  --body "$(cat <<'EOF'
Closes #<이슈번호>

## 변경 내용
- <주요 변경 1>
- <주요 변경 2>

## 테스트
- [ ] 로컬 빌드 확인
- [ ] 주요 기능 동작 확인

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

## Step 4 — 완료 보고

```
[Project PR]
PR: <URL>
base: <브랜치>
연결 이슈: #<번호>
```
