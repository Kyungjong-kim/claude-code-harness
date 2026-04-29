# API 검증 3단계 전략

> BE·풀스택 프로젝트에서 API 변경 후 기능을 검증하는 3단계 전략. **토큰 비용 낮은 순서**로 진행하고, 실서버 기동 확인은 최종 단계에서만 수행한다.
>
> 최종 업데이트: <초기_구축_날짜>

---

## 3단계 검증 흐름

| 단계 | 도구 | 토큰 비용 | 검증 항목 | 실행 조건 |
|------|------|---------|---------|---------|
| **Step 1** | 단위 테스트 | 없음 | 비즈니스 로직·유효성·예외 처리 | 항상 먼저 실행 |
| **Step 2** | 통합 테스트 (TestClient / httptest) | 없음 | 엔드포인트 요청·응답·DB 상태 | 엔드포인트 변경 시 |
| **Step 3** | 실서버 + curl | 낮음 | E2E 플로우·인증·외부 연동 | 배포 전 최종 확인 |

단계는 순서대로 진행한다. 이전 단계를 통과하지 않으면 다음 단계로 넘어가지 않는다.

---

## Step 1 — 단위 테스트 (토큰 없음)

```bash
# 전체 실행
<단위테스트_명령>

# 특정 도메인만
<단위테스트_도메인_명령>
# 예: pytest tests/test_<도메인>.py -v
# 예: go test ./internal/<패키지>/...
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

테스트 DB(인메모리 또는 테스트 전용)를 사용해 실제 엔드포인트를 호출한다.

```bash
# 통합 테스트 실행
<통합테스트_명령>
# 예: pytest tests/integration/ -v
# 예: go test ./tests/integration/...
```

**예시 패턴**

```python
# FastAPI — TestClient
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_item():
    response = client.post(
        "/api/v1/<리소스>",
        json={"<필드>": "<값>"},
        headers={"Authorization": "Bearer <테스트_토큰>"}
    )
    assert response.status_code == 201
    assert response.json()["<필드>"] == "<기대값>"
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
<서버_기동_명령>

# 헬스체크
curl localhost:<서버_포트>/health
```

```bash
# curl로 엔드포인트 확인
TOKEN="Bearer <테스트_토큰>"

# 생성
curl -s -X POST localhost:<서버_포트>/api/v1/<리소스> \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"<필드>": "<값>"}' | python3 -m json.tool

# 조회
curl -s localhost:<서버_포트>/api/v1/<리소스>/1 \
  -H "Authorization: $TOKEN" | python3 -m json.tool

# 에러 케이스
curl -s -X POST localhost:<서버_포트>/api/v1/<리소스> \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool   # → 422 확인
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

<!-- 마이그레이션 도구가 없으면 이 섹션 삭제 -->

API 변경과 별개로 마이그레이션은 반드시 아래 순서로 검증한다.

```bash
# 현재 상태 확인
<마이그레이션_상태_명령>
# 예: alembic current / alembic history

# 테스트 DB에 적용
<마이그레이션_적용_명령>
# 예: alembic upgrade head

# 롤백 테스트 (반드시 확인)
<마이그레이션_롤백_명령>
# 예: alembic downgrade -1
<마이그레이션_적용_명령>   # 재적용
```

**검증 항목:**
- `upgrade` 후 테이블·컬럼 정상 생성
- `downgrade` 후 원상 복구
- 기존 데이터 보존 여부 (data migration 포함 시)

---

## 기존 테스트 스크립트

<!-- 초기 구축 시 비어 있음. 테스트 추가 후 아래 표에 기재한다. -->

| 스크립트/파일 | 용도 |
|--------------|------|
| _(없음 — 첫 테스트 작성 후 추가)_ | |

---

## 토큰 절감 체크리스트

- [ ] Step 1 (단위 테스트) 먼저 실행 — 로직 오류 조기 발견
- [ ] 엔드포인트 변경 시 Step 2 (통합 테스트) 실행
- [ ] DB 변경 시 마이그레이션 rollback 테스트 필수
- [ ] Step 3 (실서버)은 배포 전 최종 확인에만 사용

---

## 관련 문서

- [conventions.md](./conventions.md) — 테스트 파일 네이밍·커버리지 도구 설정
- [architecture.md](./architecture.md) — DB 패턴·라우팅 구조
