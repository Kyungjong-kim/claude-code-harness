#requires -Version 5.1
<#
  Claude Code 하네스 부트스트랩 (Windows PowerShell 판)
  install.sh 의 Windows 포팅. 이 스크립트가 있는 하네스 폴더 기준으로 스킬·훅·설정을 설치한다.

  사용법:
    powershell -ExecutionPolicy Bypass -File install.ps1                 # 전역 설치 (~/.claude/skills)
    powershell -ExecutionPolicy Bypass -File install.ps1 -Local          # 프로젝트 로컬 (.claude/skills)
    powershell -ExecutionPolicy Bypass -File install.ps1 -Personal       # 개인 생산성 스킬 함께 설치
    powershell -ExecutionPolicy Bypass -File install.ps1 -Hooks          # 훅 스크립트 설치 + settings.json 등록
    powershell -ExecutionPolicy Bypass -File install.ps1 -Dir "C:\경로"   # additionalDirectories 지정
    powershell -ExecutionPolicy Bypass -File install.ps1 -Force          # 기존 스킬 덮어쓰기
    powershell -ExecutionPolicy Bypass -File install.ps1 -Yes            # 대화형 질문 없이 기본값 진행

  Windows 차이점 (install.sh 대비):
    - python3 대신 실제 python 을 탐지해 사용 (Windows Store python3 스텁 회피).
    - cp/rm 대신 robocopy /MIR 사용 (Copy-Item 중첩·Remove-Item G:\ 가드 회피).
    - 훅 등록 command 는 'bash ...' 유지 — 훅 발동에는 PATH 의 Git Bash 필요.
#>
[CmdletBinding()]
param(
  [switch]$Local,
  [switch]$Personal,
  [switch]$Hooks,
  [switch]$Force,
  [switch]$Yes,
  [string]$Dir = "",
  [string]$NotePath = ""
)
$ErrorActionPreference = 'Stop'

# 콘솔/파이썬 UTF-8 — 한글 출력 깨짐 방지 (PS 5.1 기본 cp949)
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch {}
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

# ── 경로 결정 ────────────────────────────────────────────────
$HarnessDir = $PSScriptRoot
$verFile    = Join-Path $HarnessDir 'VERSION'
$Version    = if (Test-Path $verFile) { ((Get-Content $verFile -Raw) -replace '\s','') } else { 'unknown' }
$SkillsSrc   = Join-Path $HarnessDir 'skills'
$PersonalSrc = Join-Path $HarnessDir 'personal-skills'
$HooksSrc    = Join-Path $HarnessDir 'hooks'

if ($Local) {
  $SkillsDst = Join-Path (Get-Location).Path '.claude\skills'
  $Settings  = Join-Path (Get-Location).Path '.claude\settings.json'
} else {
  $SkillsDst = Join-Path $HOME '.claude\skills'
  $Settings  = Join-Path $HOME '.claude\settings.json'
}
$HooksDst = Join-Path $HOME '.claude\hooks'

function Find-RealPython {
  foreach ($name in @('python','py')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    if ($cmd.Source -and $cmd.Source -match 'WindowsApps') { continue }  # Store 스텁 제외
    try {
      $args = if ($name -eq 'py') { @('-3','-c','import json,sys') } else { @('-c','import json,sys') }
      & $name @args 2>$null
      if ($LASTEXITCODE -eq 0) { return $name }
    } catch {}
  }
  return $null
}

# robocopy 디렉터리 미러. 종료코드 < 8 이면 성공.
function Copy-Dir($src, $dst) {
  $null = robocopy $src $dst /MIR /NFL /NDL /NJH /NJS /NC /NS /NP
  if ($LASTEXITCODE -ge 8) { throw "robocopy 실패 ($LASTEXITCODE): $src -> $dst" }
  $global:LASTEXITCODE = 0
}

# 파이썬 JSON 헬퍼. 소스를 임시 UTF-8 .py 로 써서 실행 — stdin 파이프 인코딩 손상·빈인자 드롭 회피.
# 인자는 PowerShell 네이티브 전달(Unicode 안전)이라 한글 경로도 보존된다.
function Invoke-PyJson([string]$code, [string[]]$pyArgs) {
  $tmp = Join-Path $env:TEMP ("harness_" + [guid]::NewGuid().ToString('N') + ".py")
  [System.IO.File]::WriteAllText($tmp, $code, (New-Object System.Text.UTF8Encoding $false))
  try {
    if ($Python -eq 'py') { & py -3 $tmp @pyArgs } else { & $Python $tmp @pyArgs }
  } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "=============================================="
Write-Host "   Claude Code 하네스 부트스트랩 (Windows)"
Write-Host "=============================================="
Write-Host ""
Write-Host "하네스 버전: $Version"
Write-Host "하네스 경로: $HarnessDir"
Write-Host "스킬 대상:   $SkillsDst"
Write-Host ("모드:        " + $(if ($Local) { '프로젝트 로컬 (.claude/skills)' } else { '전역 (~/.claude/skills)' }))
Write-Host ""

# ── [1/5] 의존성 확인 ────────────────────────────────────────
Write-Host "[1/5] 의존성 확인"
$hardOk = $true
foreach ($c in @('claude','git')) {
  $cmd = Get-Command $c -ErrorAction SilentlyContinue
  if ($cmd) {
    if ($c -eq 'claude') {
      $cv = (& claude --version 2>$null) -join ' '
      Write-Host "  [OK] claude $cv"
    } else { Write-Host "  [OK] $c" }
  } else {
    Write-Host "  [X] $c - 설치 필요 (필수)"
    $hardOk = $false
  }
}
$Python = Find-RealPython
if ($Python) { Write-Host "  [OK] python ($Python)" }
else { Write-Host "  [!] 실제 python 없음 - settings.json 자동 설정 불가 (스킬·훅 복사는 계속)" }
if (Get-Command gh -ErrorAction SilentlyContinue) { Write-Host "  [OK] gh (GitHub CLI)" }
else { Write-Host "  [!] gh 없음 - project-fix / project-pr / project-issue 스킬 사용 불가" }

if (-not $hardOk) {
  Write-Host ""
  Write-Host "  필수 의존성 누락. 설치 후 다시 실행하세요."
  Write-Host "    claude 없음 -> npm install -g @anthropic-ai/claude-code (Node.js 18+)"
  Write-Host "    git 없음    -> https://git-scm.com/downloads"
  exit 1
}
Write-Host ""

# ── [2/5] 프로젝트 스킬 복사 ─────────────────────────────────
Write-Host "[2/5] 프로젝트 스킬 복사"
if (-not (Test-Path $SkillsSrc)) { Write-Host "  오류: skills 폴더 없음 - $SkillsSrc"; exit 1 }
New-Item -ItemType Directory -Force -Path $SkillsDst | Out-Null
$copied = 0; $skipped = 0
foreach ($d in Get-ChildItem -Directory $SkillsSrc) {
  $dst = Join-Path $SkillsDst $d.Name
  if ((Test-Path $dst) -and -not $Force) {
    Write-Host "  스킵 (이미 존재): $($d.Name)  <- -Force 로 덮어쓰기 가능"
    $skipped++
  } else {
    Copy-Dir $d.FullName $dst
    Write-Host ("  " + $(if ($Force) { '[갱신]' } else { '[OK]' }) + " $($d.Name)")
    $copied++
  }
}
Write-Host "  -> 복사·갱신 $copied개 / 스킵 $skipped개"
Write-Host ""

# ── [3/5] 개인 생산성 스킬 ───────────────────────────────────
Write-Host "[3/5] 개인 생산성 스킬"
$doPersonal = $Personal
if (-not $Personal -and -not $Yes) {
  Write-Host "  daily-note, standup, meeting-note, til, weekly-retro, weekly-meeting-update, post-illustrate"
  $ans = Read-Host "  설치할까요? (y/N)"
  if ($ans -match '^[yY]') { $doPersonal = $true }
}
if ($doPersonal) {
  if (-not (Test-Path $PersonalSrc)) {
    Write-Host "  [!] personal-skills 폴더 없음 - 건너뜀"
  } else {
    $cp = 0; $sp = 0
    foreach ($d in Get-ChildItem -Directory $PersonalSrc) {
      $dst = Join-Path $SkillsDst $d.Name
      if (Test-Path $dst) { Write-Host "  스킵 (이미 존재): $($d.Name)"; $sp++ }
      else { Copy-Dir $d.FullName $dst; Write-Host "  [OK] $($d.Name)"; $cp++ }
    }
    Write-Host "  -> 복사 $cp개 / 스킵 $sp개"
    # 개인 노트 경로 치환
    if (-not $NotePath -and -not $Yes) { $NotePath = Read-Host "  개인 노트(Obsidian 등) 경로 (없으면 엔터)" }
    if ($NotePath) {
      $rn = 0
      foreach ($d in Get-ChildItem -Directory $SkillsDst) {
        $f = Join-Path $d.FullName 'SKILL.md'
        if ((Test-Path $f) -and (Select-String -Path $f -Pattern '<개인_노트_경로>' -SimpleMatch -Quiet)) {
          (Get-Content $f -Raw -Encoding UTF8).Replace('<개인_노트_경로>', $NotePath) | Set-Content $f -Encoding UTF8 -NoNewline
          Write-Host "  [OK] $($d.Name)"; $rn++
        }
      }
      Write-Host "  -> $rn개 스킬 노트 경로 설정: $NotePath"
    }
  }
} else {
  Write-Host "  건너뜀 - 필요하면 -Personal 플래그로 재실행."
}
Write-Host ""

# ── [4/5] settings.json 설정 ─────────────────────────────────
Write-Host "[4/5] settings.json 설정"
if (-not $Python) {
  Write-Host "  [!] 실제 python 없음 - settings.json 자동 설정 건너뜀"
  Write-Host "     수동 설정 참조: 하네스/설정_템플릿/settings.json_템플릿.md"
} else {
  if (-not $Local -and -not $Dir -and -not $Yes) {
    $Dir = Read-Host "  Claude Code 가 프로젝트 외부에서 접근할 디렉터리 (예: Obsidian Vault / 없으면 엔터)"
  }
  New-Item -ItemType Directory -Force -Path (Split-Path $Settings) | Out-Null
  $pyJson = @'
import json, pathlib, shutil, sys
settings_path = pathlib.Path(sys.argv[1])
extra_dir   = sys.argv[2].strip()
if extra_dir == "__NONE__":
    extra_dir = ""
harness_dir = sys.argv[3].strip()
local_mode  = sys.argv[4] == "1"
if extra_dir and not pathlib.Path(extra_dir).exists():
    print(f"  [!] 경로 없음: {extra_dir} - additionalDirectories 미추가")
    extra_dir = ""
data = {}
if settings_path.exists():
    try:
        data = json.loads(settings_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        bak = str(settings_path) + ".bak"
        shutil.copy2(str(settings_path), bak)
        print(f"  [!] settings.json 파싱 실패 - {bak} 백업 후 새로 생성")
if not local_mode:
    if "model" not in data:
        data["model"] = "claude-sonnet-4-6"; print("  model: claude-sonnet-4-6 설정")
    else:
        print(f"  model: {data['model']} (기존 유지)")
data.setdefault("permissions", {}).setdefault("additionalDirectories", [])
dirs = data["permissions"]["additionalDirectories"]
targets = [harness_dir] if local_mode else [extra_dir, harness_dir]
for d in targets:
    if d and d not in dirs:
        dirs.append(d); print(f"  additionalDirectories 추가: {d}")
settings_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"  저장: {settings_path}")
'@
  $localArg = if ($Local) { '1' } else { '0' }
  $dirArg   = if ($Dir) { $Dir } else { '__NONE__' }
  Invoke-PyJson $pyJson @($Settings, $dirArg, $HarnessDir, $localArg)
  if ($Local) {
    Write-Host "  [!] 로컬 설치 후: .claude/settings.json·skills 를 git 추적하면 팀원 공유 가능. 훅은 전역 설치 필요."
  }
}
Write-Host ""

# ── [5/5] 훅 스크립트 ────────────────────────────────────────
Write-Host "[5/5] 훅 스크립트 (FE/BE/풀스택)"
$doHooks = $Hooks
if (-not $Hooks -and -not $Local -and -not $Yes) {
  Write-Host "  check-source-doc.sh + pre-commit-doc-check.sh 를 ~/.claude/hooks 에 설치하고 settings.json 에 등록."
  $ans = Read-Host "  설치할까요? (y/N)"
  if ($ans -match '^[yY]') { $doHooks = $true }
}
if ($doHooks) {
  if (-not (Test-Path $HooksSrc)) {
    Write-Host "  오류: hooks 폴더 없음 - $HooksSrc"
  } else {
    New-Item -ItemType Directory -Force -Path $HooksDst | Out-Null
    $hc = 0; $hs = 0
    foreach ($f in Get-ChildItem -File -Filter '*.sh' $HooksSrc) {
      $dst = Join-Path $HooksDst $f.Name
      if ((Test-Path $dst) -and -not $Force) { Write-Host "  스킵 (이미 존재): $($f.Name) - -Force 로 덮어쓰기"; $hs++ }
      else { Copy-Item $f.FullName $dst -Force; Write-Host ("  " + $(if ($Force) {'[갱신]'} else {'[OK]'}) + " $($f.Name)"); $hc++ }
    }
    Write-Host "  -> 복사 $hc개 / 스킵 $hs개"
    Write-Host "  [i] 훅 command 는 'bash ~/.claude/hooks/..' - 발동하려면 PATH 에 Git Bash(bash) 필요."
    if ($Python) {
      $pyHooks = @'
import json, pathlib, shutil, sys
settings_path = pathlib.Path(sys.argv[1])
data = {}
if settings_path.exists():
    try:
        data = json.loads(settings_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        bak = str(settings_path) + ".bak"; shutil.copy2(str(settings_path), bak)
        print(f"  [!] 파싱 실패 - {bak} 백업. hooks 수동 등록 필요"); sys.exit(0)
hooks = data.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])
bash_hook = {"matcher": "Bash", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/pre-commit-doc-check.sh"}]}
if not any(h.get("matcher")=="Bash" and any("pre-commit-doc-check" in c.get("command","") for c in h.get("hooks",[])) for h in pre):
    pre.append(bash_hook); print("  hooks.PreToolUse (Bash) 등록 완료")
else: print("  hooks.PreToolUse (Bash) - 이미 등록됨")
post = hooks.setdefault("PostToolUse", [])
edit_hook = {"matcher": "Edit|Write", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/check-source-doc.sh"}]}
if not any(h.get("matcher")=="Edit|Write" and any("check-source-doc" in c.get("command","") for c in h.get("hooks",[])) for h in post):
    post.append(edit_hook); print("  hooks.PostToolUse (Edit|Write) 등록 완료")
else: print("  hooks.PostToolUse (Edit|Write) - 이미 등록됨")
settings_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
'@
      Invoke-PyJson $pyHooks @($Settings)
    } else {
      Write-Host "  [!] python 없음 - hooks 섹션 수동 등록 필요 (settings.json_템플릿.md 참조)"
    }
    Write-Host "  [OK] 훅 설치 완료. 프로젝트에서 /project-init 실행 시 .claude/hooks-config.sh 자동 생성."
  }
} else {
  Write-Host "  건너뜀 - 필요하면 -Hooks 플래그로 재실행."
}
Write-Host ""

# ── 완료 요약 ────────────────────────────────────────────────
Write-Host "=============================================="
Write-Host "  부트스트랩 완료"
Write-Host ""
Write-Host "  설치된 스킬:"
Get-ChildItem -Directory $SkillsDst | ForEach-Object { Write-Host "    - $($_.Name)" }
Write-Host ""
Write-Host "  다음 단계:"
Write-Host "    1. gh auth login   # project-fix·pr·issue 사용 시"
Write-Host "    2. 프로젝트 디렉터리로 이동 후 claude 실행"
Write-Host "    3. /project-init 입력"
Write-Host "=============================================="
Write-Host ""
