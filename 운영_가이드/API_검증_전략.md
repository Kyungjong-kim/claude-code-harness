---
tags: [하네스, 운영, BE, API, 검증, pytest]
updated: 2026-04-28
---

# API 검증 전략

BE·풀스택 프로젝트에서 API 변경 후 기능을 검증하는 3단계 전략.
**토큰 비용 낮은 순서**로 진행하고, 실서버 기동 확인은 최종 단계에서만 수행한다.

> FE 변경 검증은 [UI 검증 전략](UI_검증_전략.md) 참조.

---

## 3단계 검증 흐름

| 단계 | 도구 | 토큰 비용 | 검증 항목 | 실행 조건 |
|------|------|---------|---------|---------|
| **1단계** | 단위 테스트 (pytest / go test / jest) | 없음 | 비즈니스 로직·유효성·예외 처리 | 항상 먼저 실행 |
| **2단계** | 통합 테스트 (httpx / testclient / supertest) | 없음 | 엔드포인트 요청·응답·DB 상태 | 엔드포인트 변경 시 |
| **3단계** | 실서버 + curl / HTTP 클라이언트 | 낮음 | E2E 플로우·인증·외부 연동 | 배포 전 최종 확인 |

단계는 순서대로 진행한다. 이전 단계를 통과하지 않으면 다음 단계로 넘어가지 않는다.

---

## Step 1 — 단위 테스트 (토큰 없음)

```bash
# 프레임워크별 실행
pytest tests/ -v                    # Python (FastAPI / Django)
pytest tests/test_[도메인].py -v    # 특정 도메인만
go test ./...                       # Go
go test ./internal/[패키지]/...     # 특정 패키지만
npm test                            # Node.js (Express / NestJS)
```

**검증 항목:**
- 서비스 레이어 비즈니스 로직
- 입력 유효성 검사 (필수 필드, 타입, 범위)
- 예외 처리 및 에러 응답 형식
- DB 없이 목(mock) 기반 단위 검증

**언제 사용:**
- 서비스·유틸 함수 신규 추가 또는 변경
- 유효성 검사 규칙 변경
- 예외 처리 로직 변경

---

## Step 2 — 통합 테스트 (토큰 없음)

테스트 DB(SQLite 인메모리 또는 테스트 전용 PostgreSQL)를 사용해 실제 엔드포인트를 호출한다.

```python
# FastAPI — TestClient 예시
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_item():
    response = client.post(
        "/api/v1/items",
        json={"name": "test", "price": 100},
        headers={"Authorization": "Bearer <테스트_토큰>"}
    )
    assert response.status_code == 201
    assert response.json()["name"] == "test"
```

```go
// Go — httptest 예시
func TestCreateItem(t *testing.T) {
    router := setupRouter()
    w := httptest.NewRecorder()
    body := `{"name":"test","price":100}`
    req, _ := http.NewRequest("POST", "/api/v1/items", strings.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    router.ServeHTTP(w, req)
    assert.Equal(t, 201, w.Code)
}
```

**검증 항목:**
- 엔드포인트 요청 → 응답 상태 코드
- 응답 바디 구조·필드 값
- 인증 미들웨어 동작 (401 / 403 확인)
- DB 저장·조회 정상 여부 (테스트 DB 사용)
- 에러 케이스: 필수 필드 누락, 존재하지 않는 리소스

**언제 사용:**
- 신규 엔드포인트 추가
- 요청/응답 스펙 변경
- 인증·권한 로직 변경
- DB 쿼리 변경

---

## Step 3 — 실서버 기동 확인 (최종)

Step 1·2를 통과한 후 실서버를 기동해 E2E 플로우를 확인한다.

```bash
# 서버 기동
uvicorn app.main:app --reload       # FastAPI
go run ./cmd/server                 # Go
npm run dev                         # Node.js

# 헬스체크
curl localhost:8000/health
curl localhost:8080/api/health
```

```bash
# curl로 엔드포인트 확인
TOKEN="Bearer <테스트_토큰>"

# 생성
curl -s -X POST localhost:8000/api/v1/items \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"test","price":100}' | python3 -m json.tool

# 조회
curl -s localhost:8000/api/v1/items/1 \
  -H "Authorization: $TOKEN" | python3 -m json.tool

# 에러 케이스
curl -s -X POST localhost:8000/api/v1/items \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool  # → 422 Unprocessable Entity 확인
```

**검증 항목:**
- 실 서버 기동 오류 없음
- 헬스체크 엔드포인트 200 응답
- 주요 CRUD 플로우 정상 동작
- 외부 서비스 연동 (있는 경우)
- 환경변수 미설정 시 에러 발생 여부

**언제 사용:**
- 배포 전 최종 확인
- 환경변수·설정 변경 후 확인
- 외부 서비스 연동 변경 후 확인

---

## DB 마이그레이션 검증

API 검증과 별개로 마이그레이션은 반드시 아래 순서로 검증한다.

```bash
# 현재 상태 확인
alembic current          # FastAPI + Alembic
alembic history          # 마이그레이션 이력

# 테스트 DB에 적용
alembic upgrade head

# 롤백 테스트 (반드시 확인)
alembic downgrade -1     # 한 단계 롤백
alembic upgrade head     # 재적용

# Go (migrate 도구)
migrate -path ./migrations -database "$DB_URL" up
migrate -path ./migrations -database "$DB_URL" down 1
```

**검증 항목:**
- `upgrade` 후 테이블·컬럼 정상 생성
- `downgrade` 후 원상 복구
- 기존 데이터 보존 여부 (data migration 포함 시)

---

## 토큰 절감 체크리스트

BE 코드 변경 후 검증 순서:

- [ ] Step 1 (단위 테스트) 먼저 실행 — 로직 오류 조기 발견
- [ ] 엔드포인트 변경 시 Step 2 (통합 테스트) 실행
- [ ] DB 변경 시 마이그레이션 rollback 테스트 필수
- [ ] Step 3 (실서버)은 배포 전 최종 확인에만 사용

---

## 관련 문서

- [UI 검증 전략](UI_검증_전략.md) — FE 변경 시 Playwright 기반 검증
- [세션 패턴 모음](세션_패턴_모음.md) — DB 마이그레이션·API 추가 세션 패턴
- [BE_기능정리_템플릿](../Claude Code/템플릿/BE_기능정리_템플릿.md) — API 문서화 기준
