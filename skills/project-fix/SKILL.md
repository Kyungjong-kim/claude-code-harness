---
name: project-fix
description: |
  QA·버그 이슈를 받아 서브이슈 생성 + 브랜치 준비까지 원스톱으로 처리한다.
  이슈 URL 또는 번호를 받아 작업을 시작. 어느 GitHub 프로젝트에서나 사용 가능.
  트리거 키워드: "이슈 수정 시작", "버그 수정", "QA 이슈", "/project-fix"
---

# Project Fix

QA·버그 이슈를 받아 서브이슈 + 브랜치까지 원스톱으로 준비한다.

## Step 0 — 사전 확인 (git 레포 · 인증)

```bash
# git 레포 확인 (S73)
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "⚠ 현재 디렉터리가 git 저장소가 아닙니다. 프로젝트 루트로 이동 후 다시 실행하세요."
  exit 1
fi

# GitHub CLI 인증 확인 — 토큰 만료 vs 미로그인 분기 (S80)
AUTH_OUTPUT=$(gh auth status 2>&1)
```

| 결과 | 처리 |
|------|------|
| git 레포 아님 | 안내 후 중단 |
| 정상 출력 | Step 1으로 진행 |
| "not logged" 포함 | `gh auth login` 안내 후 중단 |
| "expired / token / invalid" 포함 | `gh auth refresh` 안내 후 중단 |

```
⚠ 미인증: gh auth login   # 브라우저 인증 또는 Personal Access Token 입력
⚠ 토큰 만료: gh auth refresh  # 기존 계정 토큰 갱신
gh auth status  # 확인 후 다시 /project-fix 실행
```

## Step 1 — 이슈 수집

사용자에게 이슈 URL 또는 번호를 받는다.
없으면 질문:
> "수정할 이슈 URL 또는 번호를 알려주세요."

## Step 2 — 프로젝트 컨텍스트 파악

현재 디렉토리에서 아래를 확인한다.

```bash
# GitHub remote 확인
git remote get-url origin

# 현재 브랜치 기준 브랜치 확인
git branch --show-current

# CLAUDE.md에서 브랜치 규칙 확인 (있으면)
grep -i "브랜치\|branch" CLAUDE.md 2>/dev/null | head -5
```

| 항목 | 기본값 | CLAUDE.md에 명시된 경우 |
|------|--------|------------------------|
| base 브랜치 | `main` | CLAUDE.md 규칙 우선 |
| 브랜치 접두사 | `fix/` | CLAUDE.md 규칙 우선 |
| 이슈 레이블 | 없음 | 프로젝트 레이블 사용 |

## Step 3 — 서브이슈 생성

```bash
# 원본 이슈 내용 + node ID 조회 (addSubIssue에 node ID 필요)
gh issue view <번호> --json id,title,body,labels,milestone
PARENT_ID=$(gh issue view <번호> --json id --jq .id)
```

이슈 내용을 바탕으로 서브이슈를 생성한다.

```bash
# "bug" 레이블이 존재하는 경우에만 추가
LABEL_FLAG=""
if gh label list 2>/dev/null | grep -q "^bug"; then
  LABEL_FLAG="--label bug"
fi

gh issue create \
  --title "[수정] <원본 이슈 제목>" \
  --body "$(cat <<'EOF'
Closes #<원본번호>

## 수정 내용
- 
EOF
)" \
  $LABEL_FLAG \
  --repo <감지된 repo>
```

생성된 서브이슈를 원본 이슈에 연결:
```bash
# 생성된 서브이슈 node ID 조회
CHILD_ID=$(gh issue view <서브이슈번호> --json id --jq .id)

# addSubIssue는 이슈 번호가 아닌 node ID 필요
gh api graphql -f query="mutation { addSubIssue(input: {issueId: \"$PARENT_ID\", subIssueId: \"$CHILD_ID\"}) { issue { number } } }"
```

GraphQL 실패 시 (권한 부족·GitHub 플랜 미지원·API 오류):
```
⚠ 서브이슈 자동 연결 실패 — 아래 방법으로 수동 연결하세요:
  GitHub 이슈 페이지 → 원본 이슈 #<번호> → "Sub-issues" 섹션 → 서브이슈 #<번호> 추가
```
연결 실패 여부와 관계없이 서브이슈 생성 자체는 완료됐으므로 Step 4(브랜치 생성)로 진행한다.

## Step 4 — 브랜치 생성

**QA 브랜치 감지 (S30):** 현재 브랜치가 이미 QA 브랜치(`task/` 또는 `fix/` 접두사)인 경우 새 브랜치를 생성하지 않는다.

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" =~ ^(task|fix)/ ]]; then
  echo "현재 QA 브랜치($CURRENT_BRANCH)에서 작업 중입니다."
  echo "새 브랜치를 생성하지 않고 현재 브랜치에 계속 작업합니다."
  # 서브이슈는 생성하되 브랜치 전환 없음
else
  git checkout <base 브랜치> && git pull
  git checkout -b fix/<서브이슈번호>
fi
```

CLAUDE.md에 브랜치 규칙이 있으면 그 규칙을 따른다.

## Step 5 — 완료 보고

```
[Project Fix]
원본 이슈: #<번호> — <제목>
서브이슈: #<번호> 생성 완료
브랜치: fix/<번호> (base: <base브랜치>)
→ 작업을 시작하세요.
```
