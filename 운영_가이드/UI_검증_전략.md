---
tags: [하네스, 운영, UI, 검증, playwright, 토큰]
updated: 2026-04-28
---

# UI 검증 전략

UI 변경 후 기능을 검증하는 3단계 전략. **토큰 비용 낮은 순서**로 진행하고, MCP Playwright는 최종 시각 확인 용도로만 사용한다.

---

## 3단계 검증 흐름

| 단계 | 도구 | 토큰 비용 | 검증 항목 | 실행 조건 |
|------|------|---------|---------|---------|
| **1단계** | 단위 테스트 (Jest / pytest) | 없음 | 컴포넌트 동작·접근성·이벤트 | 항상 먼저 실행 |
| **2단계** | Headless Playwright | 중간 (텍스트) | E2E 플로우·라우팅·API 통합 | 페이지 플로우 변경 시 |
| **3단계** | MCP Playwright | 높음 (이미지) | 스타일·레이아웃 시각 최종 확인 | 시각 변경이 있을 때만 |

단계는 순서대로 진행한다. 이전 단계를 통과하지 않으면 다음 단계로 넘어가지 않는다.

---

## Step 1 — 단위 테스트 (토큰 없음)

```bash
# 프레임워크별 실행
npm test          # React (Jest + Testing Library)
pytest            # Python (FastAPI 등)
pnpm test         # pnpm 워크스페이스
```

**검증 항목:**
- aria-label, data-testid 정상 부여
- 버튼 클릭 → 예상 액션 발생
- 폼 입력 → 상태 업데이트
- API 모킹 → 응답 처리 로직

**언제 사용:**
- 컴포넌트 신규 추가 또는 내부 로직 변경
- 유틸 함수·훅 변경

---

## Step 2 — Headless Playwright (토큰 중간)

`webapp-testing` 스킬의 headless 모드 활용. 이미지 없이 DOM 구조·텍스트·접근성 트리만 추출한다.

```bash
# with_server.py 헬퍼로 서버 + 스크립트 동시 실행
python scripts/with_server.py \
  --server "npm run dev" --port 5173 \
  -- python verify_flow.py
```

```python
# verify_flow.py 예시
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)  # 이미지 X
    page = browser.new_page()
    page.goto('http://localhost:5173/target-page')
    page.wait_for_load_state('networkidle')

    # 접근성 트리 추출 (텍스트만, 토큰 절약)
    snapshot = page.accessibility.snapshot()
    print(snapshot)

    # DOM 구조 검증
    assert page.locator('button[aria-label="저장"]').is_visible()

    browser.close()
```

**검증 항목:**
- 페이지 라우팅·전환 정상 작동
- API 연동 후 UI 상태 업데이트 (로딩 → 완료 → 에러)
- 폼 제출 → 리스트 갱신 플로우
- 모달·다이얼로그 열림/닫힘

**언제 사용:**
- 신규 페이지·라우트 추가
- API 연동 로직 변경
- 복잡한 사용자 인터랙션 플로우 추가

---

## Step 3 — MCP Playwright (토큰 높음, 최종만)

Step 1·2를 통과한 후 **시각 변경이 있을 때만** 사용한다.

**MCP 사용 최소화 규칙:**
- 스크린샷은 변경된 영역 위주로 3~5개만 캡처 (전체 페이지 순회 금지)
- DOM 검증은 Step 2에서 완료했으므로 MCP에서는 스크린샷만 확인
- 결과는 `docs/testing/results/<기능명>/` 에 저장

**언제 사용:**
- 스타일·색상·레이아웃 변경 (시각 회귀 가능성)
- 디자인 QA 반영 후 최종 확인
- 사용자가 화면 직접 확인을 명시적으로 요청한 경우

**MCP 없이 시각 검증이 필요하면:**
```python
# headless에서 스크린샷만 저장 → 로컬에서 직접 확인
page.screenshot(path='/tmp/result.png', full_page=True)
```

---

## 토큰 절감 체크리스트

코드 작성 후 MCP Playwright를 열기 전 확인:

- [ ] Step 1 (단위 테스트) 통과 여부 확인
- [ ] 페이지 플로우 변경 시 Step 2 (Headless) 실행
- [ ] MCP 스크린샷은 변경 영역 위주 3~5개로 제한
- [ ] 로직 변경만 있고 시각 변경 없으면 Step 3 생략

---

## 관련 스킬·문서

- `webapp-testing` — Headless Playwright 스크립트 작성 가이드 (Step 2 실행 도구)
- [세션 패턴 모음](세션_패턴_모음.md) — UI 작업 세션 패턴 전체 흐름
