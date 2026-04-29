---
tags: [하네스, 템플릿, agent, 컨텍스트]
updated: 2026-04-27
---

# agent/ 문서 템플릿

`docs/<서비스명>/agent/` 디렉토리에 위치하는 에이전트 컨텍스트 문서 3종 템플릿.
각 섹션을 분리해 해당 파일에 복사·작성한다.

> **에이전트 사용 안내**
> 이 파일은 3개의 하위 문서 템플릿을 담고 있다.
> 각 섹션(`---`로 구분)을 별도 파일로 분리해 작성한다.
>
> | 섹션 | 파일 경로 |
> |------|-----------|
> | § 1 architecture | `docs/<서비스명>/agent/architecture.md` |
> | § 2 conventions | `docs/<서비스명>/agent/conventions.md` |
> | § 3 design-system | `docs/<서비스명>/agent/design-system.md` (FE·풀스택만) |
>
> **분석 전 필수 확인 목록 — FE**
> - 소스 디렉토리 전체 구조 (`find . -maxdepth 4 -type d`)
> - `package.json` 의존성 목록 (주요 라이브러리·버전)
> - 라우팅 파일 (router.ts / App.tsx / pages/ 구조)
> - 상태 관리 패턴 (store/, context/, zustand, redux 등)
> - API 레이어 패턴 (api/, services/, hooks/use*Query 등)
> - 린터·포매터 설정 (.eslintrc, biome.json, .prettierrc)
> - 디자인 시스템 (tailwind.config, CSS 변수, 컴포넌트 라이브러리)
>
> **분석 전 필수 확인 목록 — BE**
> - 소스 디렉토리 전체 구조 (`find . -maxdepth 4 -type d`)
> - 언어·프레임워크 버전 (`pyproject.toml` / `go.mod` / `pom.xml` / `package.json`)
> - 라우팅·핸들러 구조 (routes/, handlers/, controllers/ 패턴)
> - DB 연결·ORM 패턴 (SQLAlchemy / GORM / TypeORM / Prisma 등)
> - 인증 방식 (JWT / OAuth2 / Session — 미들웨어 위치)
> - 환경변수 목록 (`.env.example` 또는 설정 파일)
> - 테스트 구조 (tests/ 위치, pytest/go test/jest 구분)

---

## § 1 — architecture.md

> 파일 경로: `docs/<서비스명>/agent/architecture.md`

```markdown
# [서비스명] 아키텍처 (에이전트용 요약)

> 이 문서는 에이전트가 작업을 시작할 때 읽는 **아키텍처 인덱스**입니다.
> 상세 내용은 `../architecture/` 디렉토리 문서를 참고합니다.
>
> **문서 신선도**: 마지막 확인 YYYY-MM-DD

---

## 1. 전체 구성도

<!-- FILL: 소스 디렉토리 분석 후 핵심 4가지만 기재

  ── FE 프로젝트 ──
  [확인 명령]
  find . -maxdepth 4 -type d | grep -E "src|pages|components|layouts|store|api"
  cat package.json | grep -E '"(react|next|vue|nuxt|vite|svelte)'

  [FE 작성 기준 — 각 항목에서 "어떻게"가 아닌 "무엇으로" 기재]
  - 앱 종류: SPA / SSR / SSG 중 선택. 근거: Vite→SPA, Next.js App Router→SSR
  - 레이아웃: 공통 레이아웃 파일 경로. 예: layouts/AppLayout.tsx가 모든 페이지를 감쌈
  - 인증: 어느 파일에서 처리. 예: AuthProvider(전역) + AuthGuard(레이아웃 단)
  - 상태: Zustand/Redux/Context 중 어느 것. 예: 서버 상태→React Query, 클라이언트→Zustand

  [FE 작성 예시]
  - **web-app**: React 19 + Vite SPA. SidebarShell 공통 골격 위에 페이지별 레이아웃.
  - **레이아웃**: `layouts/AppLayout.tsx` 단일 공통 레이아웃, 인증·사이드바 포함.
  - **인증**: `AuthProvider(전역)` → `AuthGuard(레이아웃)` 순서로 통제.
  - **상태 관리**: 서버 상태→React Query(`hooks/use*Query`), 클라이언트→Zustand(`stores/`).
  - **API 레이어**: `api/` 폴더 직접 호출 금지 → `hooks/` 훅을 통해서만 접근.

  ── BE 프로젝트 ──
  [확인 명령]
  find . -maxdepth 4 -type d | grep -E "routes|handlers|services|models|repositories|migrations"
  cat pyproject.toml 2>/dev/null || cat go.mod 2>/dev/null || cat package.json 2>/dev/null

  [BE 작성 기준]
  - 서버 종류: REST / GraphQL / gRPC 중 선택
  - 라우팅: routes/ 또는 handlers/ 구조. 예: routes/v1/user.py → /api/v1/user/* 매핑
  - 인증: 미들웨어 위치. 예: JWT → Depends(get_current_user) (FastAPI) / middleware/auth.go (Go)
  - DB 패턴: ORM 종류 + 계층 구조. 예: SQLAlchemy → models/ → repositories/ → services/

  [BE 작성 예시 — FastAPI]
  - **api-server**: FastAPI (Python 3.11). REST API 서버. routes/ 하위 도메인별 라우터 분리.
  - **라우팅**: `routes/v1/` 하위 도메인별 파일. APIRouter prefix=/api/v1/{domain}.
  - **인증**: `Depends(get_current_user)` — JWT 검증 후 user 객체 주입.
  - **DB 패턴**: PostgreSQL + SQLAlchemy ORM. `models/` → `repositories/` → `services/` 3계층.

  [BE 작성 예시 — Go]
  - **api-server**: Go 1.22 + Gin. REST API 서버. handlers/ 하위 도메인별 핸들러 분리.
  - **라우팅**: `routes/routes.go` 에서 핸들러 등록. /api/v1/ prefix.
  - **인증**: `middleware/auth.go` — JWT 검증 미들웨어. 라우터 그룹에 적용.
  - **DB 패턴**: PostgreSQL + GORM. `models/` → `repositories/` → `services/` 3계층.
-->

- **[서비스명] 앱**: [기술 스택]. [주요 구조 설명]
- **레이아웃**: [레이아웃 구조 설명]
- **인증**: [인증 처리 방식]
- **상태 관리**: [상태 관리 도구 및 패턴]
- **API 레이어**: [API 호출 패턴]

에이전트는 관련 작업 시, 반드시 위 구조를 먼저 확인하고:

1. 수정하려는 기능이 **어느 도메인/서비스** 인지
2. **어느 레이어(UI / 훅·스토어 / API)** 를 건드리는지
3. 기존 패턴 (요청 → API → 응답 → UI 갱신)에서 **어느 지점**인지

를 확인 후 작업을 시작합니다.

---

## 2. 주요 디렉토리

<!-- FILL: find 명령으로 실제 구조 파악 후 작성 -->

- `[소스루트]/` (메인 앱 소스)
  - `pages/[도메인]/` — [도메인] 서비스
  - `components/` — 공통 컴포넌트
  - `hooks/` — 커스텀 훅
  - `stores/` / `context/` — 상태 관리
  - `api/` / `services/` — API 레이어
- `docs/[서비스명]/architecture/` — 아키텍처 상세 문서
```

---

## § 2 — conventions.md

> 파일 경로: `docs/<서비스명>/agent/conventions.md`

```markdown
# [서비스명] 코딩 컨벤션 (에이전트용 요약)

> 이 문서는 에이전트가 따라야 할 코딩 규칙 인덱스입니다.
> 상세 규칙은 `../conventions/` 디렉토리 문서를 참고합니다.

---

## 1. 기준 문서

<!-- FILL: 실제 존재하는 컨벤션 문서 링크로 수정 -->

- `../conventions/[컨벤션문서명].md`
- [린터·포매터 설정 파일명] (예: `biome.json`, `.eslintrc.json`)

---

## 2. 핵심 규칙 요약

<!-- FILL: 린터·포매터 설정 파일 분석 후 작성
  분석 기준:
  - 들여쓰기: 탭/스페이스, 크기
  - 따옴표: 싱글/더블
  - 세미콜론: 있음/없음
  - 줄 길이 제한
  - import 정렬 규칙
-->

- **포매터**: [Biome / Prettier / ESLint] — 들여쓰기 [2/4]스페이스, 따옴표 [single/double]
- **세미콜론**: [있음/없음]
- **import 정렬**: [자동/수동]
- **파일 네이밍**: [PascalCase / camelCase / kebab-case]
- **컴포넌트 선언**: [함수형 / 클래스형]

---

## 3. 에이전트 작업 요약 규칙

- 새 파일/함수 추가 시:
  - [린터] 규칙을 자동 포맷에 맡긴다.
  - 기존 파일과 동일한 **디렉토리/파일 네이밍 규칙**을 유지한다.
- 리팩터링 시:
  - 기존 파일의 패턴을 우선 참조한다.

<!-- FILL: React 컴포넌트가 있는 경우 선언 순서 추가
  예: props → store → router → ref → state → derived → handler → effect → JSX
-->
```

---

## § 3 — design-system.md (FE 프로젝트만)

> 파일 경로: `docs/<서비스명>/agent/design-system.md`

```markdown
# [서비스명] 디자인 시스템 (에이전트용 가이드)

> FE 프로젝트 전용. 디자인 시스템이 없는 백엔드 프로젝트는 이 파일 생략.

---

## 1. 디자인 시스템 구조

<!-- FILL: tailwind.config / CSS 변수 파일 / 컴포넌트 라이브러리 분석 후 작성
  분석 기준:
  - 디자인 토큰 위치 (CSS 변수, tailwind extend 등)
  - 컴포넌트 라이브러리 (shadcn/ui, MUI, Radix 등)
  - Figma 연동 여부
-->

- **토큰 위치**: [CSS 변수 파일 경로 / tailwind.config.ts]
- **컴포넌트 라이브러리**: [라이브러리명 + 버전]
- **Figma 연동**: [있음/없음]

---

## 2. 작업 원칙

<!-- FILL: 디자인 토큰 사용 규칙 작성
  예: 하드코딩된 색상 사용 금지, 반드시 토큰 사용
  예: 임의 px 값 금지, spacing 토큰 사용
-->

- **색상**: 하드코딩(`#ffffff`) 금지 → 토큰(`text-[토큰명]`) 사용
- **간격**: 임의 px 금지 → spacing 토큰 사용
- **타이포그래피**: 임의 font-size 금지 → typography 토큰 사용

---

## 3. 자주 사용하는 토큰

<!-- FILL: 실제 프로젝트 토큰으로 채우기 (tailwind.config 또는 CSS 변수 파일 참조) -->

| 용도 | 토큰 | 설명 |
|------|------|------|
| 주요 텍스트 | `text-[토큰명]` | [설명] |
| 배경 | `bg-[토큰명]` | [설명] |
| 보더 | `border-[토큰명]` | [설명] |
```
