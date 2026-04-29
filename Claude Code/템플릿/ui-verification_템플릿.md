# UI 검증 3단계 전략

> UI 변경 후 기능을 검증하는 3단계 전략. **토큰 비용 낮은 순서**로 진행하고, MCP Playwright는 시각 최종 확인 용도로만 사용한다.
>
> 최종 업데이트: <초기_구축_날짜>

---

## 3단계 검증 흐름

| 단계 | 도구 | 토큰 비용 | 검증 항목 | 실행 조건 |
|------|------|---------|---------|---------|
| **Step 1** | 단위 테스트 | 없음 | 컴포넌트 동작·이벤트·훅·유틸 | 항상 먼저 실행 |
| **Step 2** | Headless Playwright | 중간 (텍스트) | E2E 플로우·라우팅·API 통합 | 페이지 플로우 변경 시 |
| **Step 3** | MCP Playwright (`<서비스명>-playwright-validator`) | 높음 (이미지) | 스타일·레이아웃 시각 최종 확인 | **사용자 승인 후** (자발 실행 ❌ / 제안은 허용) |

단계는 순서대로 진행한다. 이전 단계를 통과하지 않으면 다음 단계로 넘어가지 않는다.

---

## Step 1 — 단위 테스트 (토큰 없음)

```bash
# 프론트엔드
<단위테스트_명령>
# 예: pnpm test / npm test / vitest run

# 백엔드 (풀스택인 경우)
# <BE테스트_명령>
# 예: pytest tests/
```

**검증 항목:**
- 컴포넌트 props → 렌더링 결과
- 버튼 클릭·입력 이벤트 → 상태 업데이트
- 커스텀 훅 모킹 → 로딩·에러·성공 분기
- 유틸 함수 순수 로직

**언제 사용:**
- 컴포넌트 신규 추가 또는 내부 로직 변경
- 커스텀 훅·유틸 함수 변경

---

## Step 2 — Headless Playwright (토큰 중간)

DOM 구조·텍스트·접근성 트리만 추출해 이미지 없이 E2E 플로우를 검증한다.

**선행 조건**

| 환경 | 명령 | 포트 |
|------|------|------|
| dev 서버 | `<dev_서버_명령>` | `<dev_서버_포트>` |

### Playwright 설치 (한 번만)

```bash
npm i -g playwright
npx playwright install chromium
```

### 기존 E2E 스크립트

<!-- 초기 구축 시 비어 있음. 첫 E2E 스크립트 작성 후 아래 표에 추가한다. -->

| 스크립트 | 용도 |
|----------|------|
| _(없음 — 첫 E2E 작성 후 추가)_ | |

### E2E 예시 패턴

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("http://localhost:<dev_서버_포트>/<검증_경로>")
    page.wait_for_load_state("networkidle")

    # 접근성 트리로 구조 확인 (토큰 절약)
    snapshot = page.accessibility.snapshot()

    # DOM locator로 상세 검증
    assert page.locator('[data-testid="<testid>"]').is_visible()

    browser.close()
```

**검증 항목:**
- 페이지 라우팅·전환 정상 작동
- API 연동 후 UI 상태 업데이트 (로딩 → 완료 → 에러)
- 폼 제출·리스트 갱신 플로우
- 모달·다이얼로그 열림/닫힘

**언제 사용:**
- 신규 페이지·라우트 추가
- API 연동 로직 변경
- 복잡한 사용자 인터랙션 플로우 추가

---

## Step 3 — MCP Playwright (토큰 높음, 사용자 승인 후에만)

토큰 비용이 가장 높은 이미지 기반 검증 단계. **사용자 승인 없이 자발 실행은 금지**한다. 에이전트는 상황에 따라 **실행 여부를 제안**할 수는 있으며, 사용자가 승인했을 때만 [`<서비스명>-playwright-validator`](../../.claude/agents/<서비스명>-playwright-validator.md) 로 실행한다.

### 실행 허용 (사용자 승인 시)

- "화면 확인해줘" / "스크린샷 찍어줘" / "MCP로 검증해줘" 등 명시적 지시
- 에이전트 제안에 대한 사용자 승인 ("그래, MCP로 봐줘")
- PR 리뷰·디자인 QA 과정에서 시각 확인을 사용자가 직접 요구

### 제안 허용 (실행 금지, 제안만)

아래 상황에선 에이전트가 실행 여부를 **먼저 사용자에게 묻는다**.

- 스타일·색상·레이아웃·애니메이션 변경이 있어 시각 회귀 가능성이 있을 때
- Step 2 Headless로 판단이 어려운 미묘한 렌더링 차이가 있을 때
- 디자인 QA 반영 직후

**제안 예시**

```
Step 1·2 통과했습니다. 이번 변경에 <변경_내용>이 포함되어
시각 회귀 여부를 MCP Playwright로 3~5장 캡처해 확인하는 걸 제안드립니다.
진행할까요?
```

### 자발 실행 금지

- 사용자 승인 없이 "혹시 모르니" 자발 호출 ❌
- 스타일 변경이 있다고 자동으로 Step 3 실행 ❌
- Step 3를 스킵하되 필요 시 **제안**은 기본 경로로 포함

### MCP 사용 규칙 (승인 후 실행 시)

- 스크린샷은 변경된 영역 위주 3~5개 (전체 페이지 순회 금지)
- DOM 검증은 Step 2에서 완료했으므로 MCP에서는 스크린샷 위주로만 확인
- 결과 스크린샷은 `docs/testing/results/<기능명>/`에 저장 (필요 시)

### MCP 없이 시각 검증이 필요하면 (제안의 대안)

```python
# Step 2 Headless에서 스크린샷만 저장 → 로컬에서 직접 확인 후 사용자에게 보고
page.screenshot(path="/tmp/<서비스명>-result.png", full_page=True)
```

---

## 토큰 절감 체크리스트

코드 작성 후 아래 순서로 검증한다.

- [ ] Step 1 단위 테스트 통과
- [ ] 페이지 플로우 변경이 있다면 Step 2 Headless 실행
- [ ] **Step 3 MCP는 자발 실행 금지** — 사용자 승인 후에만 호출
- [ ] 시각 회귀 가능성이 있다면 에이전트가 먼저 **제안** (Step 3 실행 또는 Headless 스크린샷 대안)
- [ ] Step 3 실행 시 스크린샷은 변경 영역 3~5개로 제한

> ⚠️ 에이전트는 제안까지만. 사용자가 "그래" 하기 전에는 MCP를 열지 않는다.

---

## 관련 문서

- [`<서비스명>-playwright-validator`](../../.claude/agents/<서비스명>-playwright-validator.md) — Step 3 전용 에이전트 (Q8=y로 생성된 경우)
- [conventions.md](./conventions.md) — 테스트 대상 컴포넌트·훅 구조
