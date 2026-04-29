---
name: project-issue
description: |
  GitHub 이슈를 인터랙티브하게 생성한다. 상위 이슈 단독 또는 상위+하위 이슈 세트 생성.
  어느 GitHub 프로젝트에서나 사용 가능.
  트리거 키워드: "이슈 만들어줘", "이슈 생성", "하위 이슈", "/project-issue"
---

# Project Issue

GitHub 이슈를 인터랙티브하게 생성한다.

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

## Step 1 — 프로젝트 컨텍스트 파악

```bash
git remote get-url origin  # repo 감지
gh repo view --json name,owner,labels,milestones  # 레이블·마일스톤 목록 확인
```

CLAUDE.md에서 이슈 타입·레이블 규칙 확인:
```bash
grep -i "이슈\|label\|타입" CLAUDE.md 2>/dev/null | head -10
```

## Step 2 — 이슈 정보 수집

아래 질문을 순서대로 한다. 이미 사용자가 제공한 항목은 건너뛴다.

| 순서 | 질문 | 기본값 |
|------|------|--------|
| 1 | 이슈 제목이 무엇인가요? | — |
| 2 | 어떤 내용인가요? (간략히) | — |
| 3 | 하위 이슈도 함께 만들까요? | 아니오 |
| 4 | (하위 있을 때) 하위 이슈 제목·내용은? | — |

## Step 3 — 상위 이슈 생성

```bash
gh issue create \
  --title "<제목>" \
  --body "<내용>" \
  --label "<레이블>" \
  --milestone "<마일스톤>"
```

레이블·마일스톤은 프로젝트에 존재하는 것만 사용. 없으면 생략.

## Step 4 — 하위 이슈 생성 (선택)

하위 이슈 생성 후 상위 이슈에 연결:

```bash
# 상위 이슈 node ID 조회 (addSubIssue에 node ID 필요)
PARENT_ID=$(gh issue view <상위번호> --json id --jq .id)

gh issue create --title "<하위 제목>" --body "Parent: #<상위번호>"

# 생성된 하위 이슈 node ID 조회
CHILD_ID=$(gh issue view <하위번호> --json id --jq .id)

# addSubIssue는 이슈 번호가 아닌 node ID 필요
gh api graphql -f query="mutation { addSubIssue(input: {issueId: \"$PARENT_ID\", subIssueId: \"$CHILD_ID\"}) { issue { number } } }"
```

## Step 5 — 완료 보고

```
[Project Issue]
상위 이슈: #<번호> — <제목>
하위 이슈: #<번호> — <제목>  ← 생성한 경우만
→ 브랜치를 만들려면 "/project-fix <번호>" 를 사용하세요.
```
