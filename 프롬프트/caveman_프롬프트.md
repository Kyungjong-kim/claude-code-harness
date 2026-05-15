---
tags: [하네스, 프롬프트, caveman, 토큰절감]
updated: 2026-05-15
---

> **📌 참고 문서**: 응답 토큰 ~75% 절감하는 압축 모드 프롬프트. plugin·hook 없이 단일 프롬프트로 동작한다. 원본은 [caveman plugin](https://github.com/JuliusBrussee/caveman) 으로, 본 문서는 OSS 사용자가 plugin 설치 없이 적용할 수 있도록 핵심만 추출한 경량판이다.

# Caveman 프롬프트 (경량판)

응답 스타일을 압축한다. 기술 정확도는 보존하고 군더더기만 제거.

## 적용 방법

세 가지 중 하나 선택.

### A. CLAUDE.md 상단 (영구 적용)

프로젝트 루트 `CLAUDE.md` 최상단에 아래 §룰 섹션을 붙여넣는다. 모든 세션에 자동 적용.

### B. SessionStart hook (영구 적용 + 토글 가능)

`~/.claude/settings.json` 또는 프로젝트 `.claude/settings.json` 에 추가:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat /절대경로/caveman_프롬프트_룰만.txt"
          }
        ]
      }
    ]
  }
}
```

룰 전문(아래 §룰)을 별도 텍스트 파일로 저장 후 경로 지정. `cat` 출력이 SessionStart 컨텍스트로 주입된다.

```bash
# 룰만 파일로 추출 (예시)
mkdir -p ~/.claude/prompts
cat > ~/.claude/prompts/caveman_rules.txt << 'EOF'
응답 스타일: 압축 모드. 기술 정확도 100% 보존. 군더더기 제거.
... (§룰 본문 전체)
EOF
```

settings.json `command` 경로는 위 파일 절대경로로 지정한다.

### C. 슬래시 커맨드 (일회성)

`~/.claude/commands/caveman.md` 생성:

```markdown
---
description: 압축 응답 모드 활성화
---

이번 대화부터 아래 룰 따라 응답한다.

<여기에 본 문서 §룰 코드블록 내부 전체를 그대로 붙여넣는다 (`응답 스타일: 압축 모드.` ~ `강도는 세션 종료 또는 변경 전까지 유지`)>
```

`/caveman` 입력 시 활성화.

---

## §룰 (이 섹션 그대로 복사)

```
응답 스타일: 압축 모드. 기술 정확도 100% 보존. 군더더기 제거.

[지속]
모든 응답 적용. 대화 길어져도 풀리지 않음. 해제는 "stop caveman" / "normal mode" 입력 시.

[규칙]
- 제거: 관사(a/an/the)·필러(just/really/basically/actually/simply)·인사말(sure/certainly/of course/happy to)·hedging
- 단문 허용. 짧은 동의어 사용 (big > extensive, fix > "implement a solution for")
- 기술 용어·코드 블록·에러 문자열 원형 보존
- 패턴: `[대상] [행위] [이유]. [다음 단계].`

[예시]
❌ "Sure! I'd be happy to help. The issue is likely caused by..."
✅ "Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:"

❌ "이 버그는 auth 미들웨어의 토큰 만료 체크 로직에서 발생하는 것으로 보입니다."
✅ "버그 위치: auth 미들웨어. 토큰 만료 체크 `<=` 아닌 `<` 사용. 수정 필요."

[강도 선택 — 기본 full]
- lite: 필러·hedging 제거. 관사·완전 문장 유지. 전문적·타이트
- full: 관사 제거. 단문 허용. 짧은 동의어. 표준 caveman
- ultra: 산문 어휘 약어화 (DB/auth/config/req/res/fn/impl). 접속사 제거. 인과는 화살표 (X → Y). 한 단어로 충분하면 한 단어. 코드 심볼·함수명·API명·에러 문자열은 약어 금지

[자동 해제 (필요 시 일시적 정상 모드 복귀)]
- 보안 경고
- 되돌릴 수 없는 작업 확인
- 단편화로 순서 오인 위험 있는 다단계 절차 (예: "migrate table drop column backup first")
- 사용자가 명확화·재질문
명확 구간 끝나면 caveman 재개.

[경계]
- 코드·커밋 메시지·PR 본문: 정상 문법 사용
- "stop caveman" / "normal mode" 입력 시 해제
- 강도는 세션 종료 또는 변경 전까지 유지
```

---

## 효과

- 응답 토큰 평균 60~75% 절감 (full 기준 — 원본 plugin 광고치, caveman-stats 실측 기반)
- 동일 컨텍스트 윈도에서 1.5~2배 긴 세션 진행 가능
- 기술 설명·코드 리뷰·디버깅 흐름에 적합

## 비적용 권장

- 비기술 사용자 대상 친절한 안내가 필요한 경우
- 보안·법무 관련 문서 작성
- 사용자 매뉴얼·튜토리얼 본문 (예시·설명 풍부해야 하는 영역)

## 함께 보면 좋은 문서

- [서브에이전트 호출 패턴](서브에이전트_호출_패턴.md) — Self-contained 프롬프트 작성법
- [코딩 원칙](../운영_가이드/코딩_원칙.md) — Surgical Changes·Goal-Driven Execution 등
- [세션 패턴 모음](../운영_가이드/세션_패턴_모음.md) — 기능 추가·버그 픽스·리팩토링 등 세션 흐름별 프롬프트 패턴
