---
name: doc-drift
description: |
  기능 개발 문서(FE_*.md·BE_*.md 등)가 실제 코드 변경을 따라가지 못해 노후화된 것을 탐지한다.
  문서가 참조하는 source 파일이 문서 최종 갱신 이후 변경됐는지 git 이력으로 비교해 stale 문서를 리포트한다.
  문서 신뢰성 점검·주기 감사 시 사용. 어느 프로젝트에서나 사용 가능.
  트리거 키워드: "문서 drift", "문서 노후", "stale 문서", "기능문서 점검", "문서-코드 동기화", "doc drift", "/doc-drift"
---

# Doc Drift

> 기능 문서를 작성·갱신하는 규율(게이트)이 문서 *작성*은 닫아도, 코드만 바뀌고 문서가 안 따라간 *노후*는 못 막는다.
> 이 스킬은 문서가 참조하는 source 파일의 git 변경 시점을 문서 갱신 시점과 비교해 stale 문서를 찾는다.
> **읽기 전용 — 탐지만.** 발견 후 사용자 확인 하에 갱신.

저장소 루트에서 실행. 특정 영역만 보려면 인자로 경로 전달(예: `src/docs/pages`).

> **쉘 호환(중요)**: 모든 쉘(bash·zsh·sh/dash)에서 동작하도록 작성. 금지 — `for x in $var`(zsh 단어분리 안 함), `< <(...)`(POSIX sh 미지원). **임시파일 redirect**(`done < "$tmp"` — 카운터 유지)와 **내부 파이프 결과 캡처**(`result=$(... | while read)`)를 쓴다.
> **경로 주의**: 문서의 source 경로는 보통 **프로젝트 루트 기준 상대경로**(`src/...`)다. 모노레포면 문서가 속한 패키지 prefix를 붙여 해소한다(`resolve()`).

### 통합 실행 (영역 인자 선택)

```bash
SCOPE="${ARGS:-.}"
tmp=$(mktemp)
# 문서 파일 패턴은 프로젝트 컨벤션에 맞게 조정 (예: FE_*.md·BE_*.md)
find $SCOPE \( -name "FE_*.md" -o -name "BE_*.md" \) -not -path "*/node_modules/*" -not -path "*/archive/*" > "$tmp"

proj_prefix() {  # 문서 경로 → source 상대경로 앞에 붙일 패키지 prefix (모노레포 대응)
  case "$1" in
    */docs/*) printf '%s/' "$(echo "$1" | cut -d/ -f1)" ;;  # <pkg>/docs/... → <pkg>/
    *)        printf '' ;;                                   # 루트 docs/... → prefix 없음
  esac
}
resolve() { for c in "$2$1" "$1"; do [ -e "$c" ] && { printf '%s' "$c"; return 0; }; done; return 1; }

stale_n=0; ok_n=0; unverif=0; nofield=0
while IFS= read -r doc; do
  [ -z "$doc" ] && continue
  grep -q "최종 확인\|Last verified\|last-verified" "$doc" || nofield=$((nofield+1))
  doc_epoch=$(git log -1 --format=%ct -- "$doc" 2>/dev/null)
  [ -z "$doc_epoch" ] && { echo "⚠️ 미커밋(비교 불가): $doc"; continue; }
  prefix=$(proj_prefix "$doc")

  # 각 줄: "STALE|경로|날짜" 또는 "OK"
  result=$(grep -oE '`[A-Za-z0-9_./-]+`' "$doc" | tr -d '`' \
            | grep -E '/(src|pages|views|api|store|components|hooks|services|routers|crud|models|schemas|lib|app)/' \
            | grep -vE '<|\*' | sort -u \
            | while IFS= read -r s; do
                real=$(resolve "$s" "$prefix") || continue
                se=$(git log -1 --format=%ct -- "$real" 2>/dev/null); [ -z "$se" ] && continue
                if [ "$se" -gt "$doc_epoch" ]; then echo "STALE|$real|$(git log -1 --format=%cd --date=short -- "$real")"
                else echo "OK"; fi
              done)
  checked=$(printf '%s\n' "$result" | grep -c '.')
  scnt=$(printf '%s\n' "$result" | grep -c '^STALE|')
  printf '%s\n' "$result" | grep '^STALE|' | sed 's/^STALE|/   ↳ source 변경됨: /; s/|/ (/; s/$/)/'

  if   [ "$checked" -eq 0 ]; then unverif=$((unverif+1)); echo "❓ source 미해소(검증 불가): $doc"
  elif [ "$scnt"   -gt 0 ];  then stale_n=$((stale_n+1)); echo "❌ STALE: $doc (문서 최종 $(git log -1 --format=%cd --date=short -- "$doc"))"
  else ok_n=$((ok_n+1)); fi
done < "$tmp"
rm -f "$tmp"

echo "---- STALE:$stale_n  최신:$ok_n  검증불가:$unverif  최종확인누락:$nofield ----"
```

---

## 리포트 형식

```
[기능 문서 Drift 감사]
- 대상 문서: N건
- ❌ STALE (코드가 문서보다 최신): M건 — 변경된 source 목록 포함
- ❓ 검증 불가 (참조 source 없음): K건
- ⚠️ 최종확인 필드 누락: J건

권장: STALE 문서를 갱신. source 경로를 충실히 적은 문서일수록 정확.
```

**한계**: source 경로를 문서에서 추출 못 하면 검증 불가(❓). git 미커밋 변경은 비교 대상 아님. "STALE"은 거친 휴리스틱(source 변경=문서보다 최신) — 트리아지 목록이지 확정 오류 아님.
