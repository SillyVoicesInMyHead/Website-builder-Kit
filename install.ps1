# Website Builder Kit installer for Windows (PowerShell 5.1 or later).
# Usage: powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Yes] [-Target DIR]
#   -Yes      use the default answers, ask nothing
#   -Target   skills folder (default %USERPROFILE%\.claude\skills; use ~\.agents\skills for Codex)
param(
  [switch]$Yes,
  [string]$Target = (Join-Path $env:USERPROFILE '.claude\skills')
)
$ErrorActionPreference = 'Stop'
$KitDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Ask([string]$q, [string]$def) {
  if ($Yes) { return $def }
  $a = Read-Host "$q [$def]"
  if ([string]::IsNullOrWhiteSpace($a)) { return $def }
  return $a.Trim()
}
function YesNo([string]$q, [string]$def) {
  $a = Ask "$q (y/n)" $def
  return ($a -match '^(y|yes)$')
}

Write-Host 'Website Builder Kit'
Write-Host "Installing into: $Target"
New-Item -ItemType Directory -Force -Path $Target | Out-Null
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# 1. The kit's own skills
foreach ($s in 'website-builder', 'skill-sharpen', 'usage-audit') {
  $dest = Join-Path $Target $s
  if (Test-Path $dest) {
    Rename-Item $dest "$s.bak-$Stamp"
    Write-Host "  Backed up existing $s to $s.bak-$Stamp"
  }
  Copy-Item -Recurse (Join-Path $KitDir "skills\$s") $dest
  Write-Host "  Installed $s"
}

# 2. Settings
Write-Host ''
Write-Host "Settings (press Enter for the default; change later by editing $Target\website-builder\config.json)"
$maxAgents = Ask 'Most helper agents at once (0 = none, 3, 6, or any number)' '3'
if ($maxAgents -notmatch '^\d+$') { $maxAgents = '3' }
$session = Ask 'Session size: small (cheapest), normal, large' 'normal'
if ($session -notin 'small', 'normal', 'large') { $session = 'normal' }
$config = [ordered]@{
  max_agents         = [int]$maxAgents
  session_size       = $session
  handoff_at_end     = (YesNo 'Offer a handoff summary and a fresh chat when a site is done?' 'y')
  write_docs         = (YesNo 'Write a README for each finished site?' 'y')
  model_read         = (Ask 'Model for helper agents that read and search' 'haiku')
  model_write        = (Ask 'Model for helper agents that write code' 'sonnet')
  screenshots        = (YesNo 'Take screenshots during the check phase?' 'y')
  ask_before_publish = $true
}
$json = $config | ConvertTo-Json
[System.IO.File]::WriteAllText((Join-Path $Target 'website-builder\config.json'), $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host '  Saved settings'

# 3. Companion skills and the design library (downloaded from their own GitHub repos)
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) "wbkit-$Stamp"
function Fetch([string]$repo) {
  $dir = Join-Path $Tmp ($repo -replace '/', '_')
  if (-not (Test-Path $dir)) { git clone --depth 1 --quiet "https://github.com/$repo.git" $dir | Out-Null }
  return $dir
}
function Place([string]$repo, [string]$path, [string]$name) {
  $src = Join-Path (Fetch $repo) $path
  $dest = Join-Path $Target $name
  if (-not (Test-Path $src)) { Write-Host "  Skipped $name (not found in $repo)"; return }
  if (Test-Path $dest) { Write-Host "  Kept your existing $name"; return }
  Copy-Item -Recurse $src $dest
  Write-Host "  Installed $name from $repo"
}

Write-Host ''
Write-Host 'Companion skills come from their authors'' GitHub repos. Read them before you trust them.'
$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
if ($hasGit -and (YesNo 'Download companion skills and the design library now?' 'y')) {
  New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
  try {
    if (YesNo '  Design library: 70+ real brand DESIGN.md files (VoltAgent/awesome-design-md)' 'y') {
      $lib = Join-Path (Fetch 'VoltAgent/awesome-design-md') 'design-md'
      $libDest = Join-Path $Target 'website-builder\library\design-md'
      New-Item -ItemType Directory -Force -Path (Split-Path $libDest) | Out-Null
      if (Test-Path $libDest) { Remove-Item -Recurse -Force $libDest }
      Copy-Item -Recurse $lib $libDest
      Write-Host '  Installed design library'
    }
    if (YesNo '  Design and testing (anthropics/skills: frontend-design, webapp-testing)' 'y') {
      Place 'anthropics/skills' 'skills/frontend-design' 'frontend-design'
      Place 'anthropics/skills' 'skills/webapp-testing' 'webapp-testing'
    }
    if (YesNo '  Motion and anti-slop (AThevon/genjutsu: tells, motion-principles, css-native, desktop-principles)' 'y') {
      foreach ($s in 'tells', 'motion-principles', 'css-native', 'desktop-principles') { Place 'AThevon/genjutsu' "skills/_jutsu/$s" $s }
    }
    if (YesNo '  Accessibility review (vercel-labs/agent-skills: web-design-guidelines)' 'y') {
      Place 'vercel-labs/agent-skills' 'skills/web-design-guidelines' 'web-design-guidelines'
    }
    if (YesNo '  Speed (addyosmani/web-quality-skills: core-web-vitals, performance)' 'y') {
      Place 'addyosmani/web-quality-skills' 'skills/core-web-vitals' 'core-web-vitals'
      Place 'addyosmani/web-quality-skills' 'skills/performance' 'performance'
    }
    if (YesNo '  Playwright tests (currents-dev/playwright-best-practices-skill)' 'n') {
      Place 'currents-dev/playwright-best-practices-skill' 'playwright-best-practices' 'playwright-best-practices'
    }
    if (YesNo '  Cloudflare deploy (cloudflare/skills: wrangler, workers-best-practices)' 'n') {
      Place 'cloudflare/skills' 'skills/wrangler' 'wrangler'
      Place 'cloudflare/skills' 'skills/workers-best-practices' 'workers-best-practices'
    }
    if (YesNo '  Skill safety check (NVIDIA/SkillSpector: skill-inspector)' 'y') {
      Place 'NVIDIA/SkillSpector' 'skills/skill-inspector' 'skill-inspector'
      Write-Host '    The scanner itself is a separate install. If you have uv:'
      Write-Host '    uv tool install --python 3.13 git+https://github.com/NVIDIA/skillspector.git'
    }
    if (YesNo '  Video to notes (willmottjack11-bot/video-to-skill; needs its own setup and API keys for some videos)' 'n') {
      $dest = Join-Path $Target 'video-to-skill'
      if (Test-Path $dest) { Write-Host '  Kept your existing video-to-skill' }
      else {
        Copy-Item -Recurse (Fetch 'willmottjack11-bot/video-to-skill') $dest
        $g = Join-Path $dest '.git'; if (Test-Path $g) { Remove-Item -Recurse -Force $g }
        Write-Host '  Installed video-to-skill (run its setup on first use)'
      }
    }
  }
  finally {
    if (Test-Path $Tmp) { Remove-Item -Recurse -Force $Tmp }
  }
}
else {
  Write-Host '  Skipped companions. The skill still works using its own reference files.'
}

Write-Host ''
Write-Host 'Optional progress bar mod (savvy-progress): see'
Write-Host '  https://github.com/JohnnyVizz/claude-kit/tree/main/plugins/savvy-progress'
Write-Host ''
Write-Host 'Done. Start a new Claude Code chat and say: build me a website'
