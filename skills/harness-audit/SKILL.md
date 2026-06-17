---
name: harness-audit
description: |
  Claude Code 하네스(.claude/agents·skills, CLAUDE.md, 가이드 문서)의 끊긴 배선을 스캔한다.
  삭제·리네임된 에이전트/스킬/문서 참조, 존재하지 않는 경로, 고아 항목을 탐지해 리포트한다.
  에이전트·스킬을 추가·삭제·이름변경한 직후, 또는 주기 점검 시 사용. 어느 프로젝트에서나 사용 가능.
  트리거 키워드: "하네스 감사", "배선 점검", "dangling 참조", "끊긴 참조", "harness audit", "/harness-audit"
---

# Harness Audit

> **읽기 전용 — 탐지만.** 수정은 발견 후 사용자 확인 하에.

저장소 루트에서 실행. 스캔 대상은 `CLAUDE.md`·`.claude/agents`·`.claude/skills`·하네스 가이드 문서(있으면 `docs/`).

> **쉘 호환**: 모든 쉘(bash·zsh·sh/dash) 동작 보장. 금지 — `for x in $var`/`for x in $(...)`(zsh 단어분리 안 함, 첫 항목만 돔), `< <(...)`(POSIX sh 미지원). `... | while IFS= read -r` 파이프 패턴만 사용(아래 검사는 출력 전용이라 서브셸 무관).

아래 예시는 스캔 범위를 `SCAN`으로 둔다. 프로젝트 구조에 맞게 조정한다:
```bash
SCAN="CLAUDE.md $(ls .claude/agents/*.md 2>/dev/null) $(ls .claude/skills/*/SKILL.md 2>/dev/null) $(ls docs/**/*.md 2>/dev/null)"
```

---

## 스캔 절차

### 1. 정의 없는 에이전트 참조

```bash
existing=$(ls .claude/agents/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md//')
grep -hoE '`[a-z][a-z0-9-]+`' $SCAN 2>/dev/null \
  | tr -d '`' | sort -u \
  | grep -E '(-dev|-writer|-reviewer|debugger|architect|refactor|reviewer|validator|designer|tester)$' \
  | while read r; do echo "$existing" | grep -qx "$r" || echo "❌ 정의없음: $r"; done
```
> 오탐: 하위 디렉터리(모노레포 패키지)의 `<pkg>/.claude/agents/`에 정의된 에이전트는 루트에 없어도 정상.

### 2. 정의 없는 스킬 참조

```bash
skills=$(ls -d .claude/skills/*/ 2>/dev/null | xargs -n1 basename)
grep -hoE '/[a-z][a-z0-9-]+|`[a-z][a-z0-9-]+`' $SCAN 2>/dev/null \
  | tr -d '`/' | sort -u \
  | while read s; do [ -d ".claude/skills/$s" ] || echo "$s"; done
```
> 위는 후보가 많다(일반 단어 포함). **슬래시 커맨드로 참조된 것(`/skill-name`)** 위주로 좁혀 판단. 전역/플러그인 스킬은 오탐.

### 3. 존재하지 않는 경로 참조

```bash
grep -hoE '\.claude/[A-Za-z0-9_./-]+' $SCAN 2>/dev/null \
  | grep -vE '<|\*' | sort -u | while read p; do [ -e "$p" ] || echo "❌ MISSING: $p"; done
grep -hoE 'docs/[A-Za-z0-9_./-]+\.md' $SCAN 2>/dev/null \
  | sort -u | while read p; do [ -f "$p" ] || echo "❌ MISSING: $p"; done
```
> 오탐: `~/.claude/...`(글로벌, `~` 탈락), 프로젝트별 상대경로(모노레포 하위 패키지 기준)는 루트에 없어도 정상.

### 4. 고아 에이전트 (정의됐으나 참조처 없음)

```bash
ls .claude/agents/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md//' | while IFS= read -r a; do
  cnt=$(grep -rl "$a" $SCAN 2>/dev/null | grep -v "agents/$a.md" | wc -l)
  [ "$cnt" -eq 0 ] && echo "⚠️ 고아: $a"
done
```
> 고아 ≠ 즉시 삭제. 직접 호출용일 수 있으니 의도 확인 후 판단.

### 5. 폐기 항목 잔존 확인 (인자 = 폐기한 이름들)

```bash
echo "$ARGS" | tr ' ' '\n' | while IFS= read -r name; do
  [ -z "$name" ] && continue
  echo "=== $name ==="
  grep -rn "$name" $SCAN 2>/dev/null || echo "0 ✓"
done
```

---

## 리포트 형식

```
[하네스 감사 결과]
- 정의 없는 에이전트/스킬 참조: <목록 또는 0>
- 끊긴 경로: <목록 또는 0>
- 고아 에이전트: <목록 또는 0>
- 오탐 제외 실제 조치 필요: <N건>

권장 조치: <파일:줄 → 수정안>
```
