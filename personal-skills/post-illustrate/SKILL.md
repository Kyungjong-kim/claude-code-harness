---
name: post-illustrate
description: |
  블로그 글(.md)을 읽고 글에 필요한 이미지 매니페스트를 생성한다.
  판단(어떤 이미지가 필요한가)은 LLM이, 렌더(이미지화)는 외부 무료 도구가 담당하는 분업.
  각 이미지마다 배치 위치·종류·생성 소스(Mermaid 텍스트 / Excalidraw 노트 / 코드캡처 대상 / 커버 프롬프트)를 만든다.
  트리거 키워드: "글 이미지", "포스트 일러스트", "블로그 이미지 매니페스트", "다이어그램 뽑아줘", "/post-illustrate"
---

# Post Illustrate

> "파일 넣으면 이미지 나오는" 턴키 서비스는 없다. 어떤 이미지가 필요한지 판단하는 건 LLM 몫이다.
> 이 스킬은 글을 읽고 **이미지 매니페스트**(렌더 가능한 소스 + 프롬프트)를 만든다. 실제 이미지화는 아래 무료 도구로.

입력: 블로그 글 `.md` 경로(인자). 출력: 같은 폴더에 `<글파일명>.images.md` 매니페스트.

---

## 절차

### 1. 글 분석

- 글을 읽고 **시각화 가치가 높은 개념**을 찾는다(흐름·구조·before/after·계층·분기·대비).
- 글 성격 판별:
  - **개념/아키텍처/프로세스 글** → 다이어그램 위주(Mermaid). 본문이 이미 표를 가지면 중복 다이어그램 자제.
  - **튜토리얼/실습 글** → 터미널·화면 캡처 대상 위주.
- **과다 금지**: 글당 이미지 2~5장. 모든 섹션에 넣지 않는다. 텍스트로 충분한 곳은 비워둔다.

### 2. 이미지 종류별 산출물 생성

| 종류 | 언제 | 산출물 |
|------|------|--------|
| 커버(표지) | 글당 1장 | **권장: SVG 템플릿**(시리즈 일관 브랜딩, 로컬 렌더, AI 불요) — 제목·번호·부제만 교체. 대안: AI 이미지 프롬프트(영문 16:9 미니멀) |
| 개념 다이어그램 | 흐름·구조·분기 | **Mermaid 텍스트**(flowchart/sequence). 박스+화살표 심플 |
| before/after·대비 | 변화 설명 | Mermaid subgraph 2개 또는 좌우 비교 |
| 손그림 풍 | 가벼운 개념 | Excalidraw로 그릴 요소 설명(텍스트 가이드) |
| 코드·터미널 캡처 | 실행 결과·스니펫 | 캡처할 출력 텍스트 + carbon/ray.so 설정(테마·언어) |

### 3. 매니페스트 작성

`<글파일명>.images.md`에 이미지별로:
```
## [IMG-N] <배치: 어느 섹션 뒤> · <종류>
- 목적: <이 이미지가 전달할 것 한 줄>
- 렌더: <도구 + 방법>
- 파일명(권장): <slug>-<n>-<keyword>.png
- 소스/프롬프트:
  ```
  <Mermaid 텍스트 / 커버 프롬프트 / 캡처 대상>
  ```
```

### 4. 렌더 가이드(매니페스트 말미에 고정 삽입)

- **Mermaid (로컬 고화질 렌더 — 권장)**: mmdc로 직접 PNG 생성. **화질 필수 옵션**:
  ```bash
  # puppeteer.json: {"args":["--no-sandbox","--disable-setuid-sandbox"]}
  npx -y @mermaid-js/mermaid-cli -i in.mmd -o out.png -b white -s 3 -w 1000 -p puppeteer.json
  ```
  - `-s 3` (scale 3x) — **1x 기본은 블로그 업로드 시 글자 깨짐**. 3x 필수.
  - `-b white` — velog 가독성(투명 배경은 테마 따라 안 보임).
  - **레이아웃**: 단계 4개 이상 흐름은 `flowchart TB`(세로). `LR`(가로)은 긴 흐름서 4000px+ 납작 이미지 → 폭 맞추면 글자 깨알. before/after도 TB 세로 스택.
- **Mermaid (웹)**: [mermaid.live](https://mermaid.live) 붙여넣기 → Export.
- **xychart-beta (막대/선 차트)**: mermaid 11+ 지원. **한글 라벨은 반드시 따옴표로 감쌀 것**(`x-axis ["부트스트랩","1개월 후"]`, `title "..."`) — 비ASCII 미따옴표 시 렌더 실패. 브랜드 색: `%%{init:{"themeVariables":{"xyChart":{"plotColorPalette":"#6366f1"}}}}%%`.
- **커버 썸네일 (SVG 템플릿 → rsvg-convert)**: 시리즈 일관 디자인. 1280×720 SVG에 그라데이션 배경·글로우·시리즈 배지·제목(번호·부제)·모티프(에디터 윈도우 등)·푸터. 글마다 **제목/번호/부제/모티프 라벨만 교체**. 고해상 렌더:
  ```bash
  rsvg-convert -w 2560 -h 1440 cover.svg -o cover.png   # 2x = 선명
  ```
  - Korean 폰트: `font-family="Apple SD Gothic Neo, sans-serif"` (rsvg가 fontconfig로 해소).
  - 일관성: 배경 그라데이션·배지·푸터·레이아웃 고정, 콘텐츠만 글별 교체 → 시리즈 통일감.
- **Excalidraw**: [excalidraw.com](https://excalidraw.com) — 가이드대로 그리거나 Mermaid→Excalidraw 변환 기능 사용.
- **코드/터미널**: [carbon.now.sh](https://carbon.now.sh) / [ray.so](https://ray.so) — 출력 붙여넣기 → 이미지.
- **커버**: DALL·E / GPT-image / Midjourney / Stable Diffusion에 프롬프트 입력.
- **velog 주의**: mermaid 네이티브 렌더 불확실 → **미리 PNG/SVG로 렌더해 업로드**.

---

## 🔴 마스킹 (공개 이미지)

다이어그램·커버·캡처는 공개 자산이다. 사내·제품·실명·실제 경로·이슈번호가 이미지에 들어가지 않도록 한다. 본문이 이미 마스킹돼 있어도, 다이어그램 라벨·캡처 텍스트에서 재확인한다.

## 주의

- 매니페스트는 **소스/프롬프트만** 만든다. 이미지 파일 자체는 사용자가 도구로 렌더한다(LLM은 바이너리 생성 안 함).
- 글이 이미 충분히 설명적이면 "이미지 불요" 섹션으로 그 사실을 적는다 — 억지로 채우지 않는다.
