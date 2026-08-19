---
name: weekly-meeting-update
description: |
  <프로젝트> 주간 FE 회의록의 <서비스명> 섹션을 이번주 실제 작업 기반으로 자동 생성한다.
  트리거 키워드: "주간회의록", "회의록 업무 정리", "회의록 <서비스명> 업데이트", "/weekly-meeting-update".
  작업 영역을 파라미터로 받으며 기본값은 <서비스명>.
  이번주 커밋·HANDOFF 문서를 취합해 금주/차주 계획 블록을 회의록 마크다운으로 출력한다.
---

> ⚠️ **설치 후 필수**: 이 파일의 `<개인_노트_경로>`를 실제 노트 경로로 교체해야 정상 동작한다.
> 교체 방법: `README.md`의 "개인 스킬에 노트 경로 연결" 섹션 참조.

# Weekly Meeting Update

<프로젝트> 주간 회의록 중 **<서비스명> 섹션**을 이번주 실제 작업 기반으로 생성한다.  
회의록 전체가 아닌 **<서비스명> 블록만** 출력한다.

## 워크플로우

### Step 1 — 이번주 월요일 계산

```bash
python3 -c "
from datetime import date, timedelta
today = date.today()
monday = today - timedelta(days=today.weekday())
print(monday.isoformat())
"
```

### Step 2 — 데이터 수집 (3개 병렬 실행)

| 항목 | 명령 / 경로 |
|------|------------|
| **HANDOFF_NOW.md** | `<서비스명>/docs/status/HANDOFF_NOW.md` 읽기 |
| **HANDOFF.md** | `<서비스명>/docs/plans/HANDOFF.md` 읽기 |
| **이번주 커밋** | `git log --oneline --since="<MONDAY>" -- <서비스명>/` |

<서비스명2> 영역이면 경로를 `<서비스명2>/docs/...`로 교체한다.

커밋 메시지에서 `#숫자` 패턴으로 이슈 번호를 추출한다.  
이슈 번호가 없는 커밋(문서, 설정 변경 등)은 내용으로 판단해 적절히 분류한다.

### Step 3 — 작업 분류

HANDOFF 세션 내역 + 커밋을 아래 카테고리로 분류한다.  
해당 주에 없는 카테고리는 생략한다.

| 카테고리 | 포함 기준 |
|----------|----------|
| QA 대응 및 버그 수정 | `[QA]` 이슈, 버그 픽스, 잔버그 처리 |
| 기능 개발 | 신규 기능, API 연동, 컴포넌트 신규 구현 |
| 기획 QA 반영 | 기획 QA, UX 흐름 변경 |
| 디자인 QA 반영 | 디자인 QA, 스타일 수정, 디자인 토큰 적용 |
| nginx / 인프라 | nginx conf, 배포 설정, MIME 타입 |

카테고리가 1~2개뿐이면 카테고리 헤더 없이 플랫 리스트로 출력해도 된다.

### Step 4 — 출력

출력 형식과 예시는 [references/output-format.md](references/output-format.md)를 참조한다.

핵심 규칙:
- 이슈 번호 → 반드시 GitHub 링크: `[#번호](https://github.com/<조직>/<프로젝트>/issues/번호)`
- **금주 계획**: 이번주 실제 완료 작업 (카테고리별 그룹)
- **차주 계획**: HANDOFF_NOW.md §2 다음 작업 기반
- 담당자: `@<담당자>` (git user: <git_사용자명>)
- 동일 이슈가 여러 커밋/세션에 걸쳐 있으면 한 줄로 합쳐서 표현한다
- HANDOFF.md 세션 내역이 커밋보다 상세하므로 HANDOFF 내역을 우선 활용한다
