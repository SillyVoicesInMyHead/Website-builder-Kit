#!/usr/bin/env bash
# Website Builder Kit installer for macOS and Linux (and Git Bash on Windows).
# Usage: ./install.sh [--yes] [--target DIR]
#   --yes      use the default answers, ask nothing
#   --target   skills folder (default ~/.claude/skills; use ~/.agents/skills for Codex)
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/skills"
YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) YES=1 ;;
    --target) TARGET="$2"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

ask() { # ask "question" default -> echoes answer
  local q="$1" def="$2" a
  if [ "$YES" = 1 ]; then echo "$def"; return; fi
  read -r -p "$q [$def]: " a </dev/tty || true
  echo "${a:-$def}"
}
yesno() { # yesno "question" y|n -> returns 0 for yes
  local a; a="$(ask "$1 (y/n)" "$2")"
  case "$a" in y|Y|yes|Yes) return 0 ;; *) return 1 ;; esac
}

echo "Website Builder Kit"
echo "Installing into: $TARGET"
mkdir -p "$TARGET"
STAMP="$(date +%Y%m%d-%H%M%S)"

# 1. The kit's own skills
# Backups go next to the skills folder, not inside it, so they never load as duplicate skills.
BACKUP="$(dirname "$TARGET")/skill-backups/$STAMP"
for s in website-builder skill-sharpen usage-audit; do
  if [ -d "$TARGET/$s" ]; then
    mkdir -p "$BACKUP"
    mv "$TARGET/$s" "$BACKUP/$s"
    echo "  Backed up existing $s to $BACKUP/$s"
  fi
  cp -R "$KIT_DIR/skills/$s" "$TARGET/$s"
  echo "  Installed $s"
done
# Keep an already-downloaded design library and any local notes on a re-run
for keep in library local.md; do
  if [ -e "$BACKUP/website-builder/$keep" ]; then
    cp -R "$BACKUP/website-builder/$keep" "$TARGET/website-builder/$keep"
    echo "  Kept your existing website-builder/$keep"
  fi
done

# 2. Settings
echo
echo "Settings (press Enter for the default; change later by editing $TARGET/website-builder/config.json)"
MAX_AGENTS="$(ask 'Most helper agents at once (0 = none, 3, 6, or any number)' 3)"
case "$MAX_AGENTS" in ''|*[!0-9]*) MAX_AGENTS=3 ;; esac
SESSION="$(ask 'Session size: small (cheapest), normal, large' normal)"
case "$SESSION" in small|normal|large) ;; *) SESSION=normal ;; esac
if yesno 'Offer a handoff summary and a fresh chat when a site is done?' y; then HANDOFF=true; else HANDOFF=false; fi
if yesno 'Write a README for each finished site?' y; then DOCS=true; else DOCS=false; fi
MODEL_READ="$(ask 'Model for helper agents that read and search' haiku)"
MODEL_WRITE="$(ask 'Model for helper agents that write code' sonnet)"
if yesno 'Take screenshots during the check phase?' y; then SHOTS=true; else SHOTS=false; fi

cat > "$TARGET/website-builder/config.json" <<EOF
{
  "max_agents": $MAX_AGENTS,
  "session_size": "$SESSION",
  "handoff_at_end": $HANDOFF,
  "write_docs": $DOCS,
  "model_read": "$MODEL_READ",
  "model_write": "$MODEL_WRITE",
  "screenshots": $SHOTS,
  "ask_before_publish": true
}
EOF
echo "  Saved settings"

# 3. Companion skills and the design library (downloaded from their own GitHub repos)
fetch() { # fetch owner/repo -> echoes local clone path
  local dir="$TMP/$(echo "$1" | tr '/' '_')"
  [ -d "$dir" ] || git clone --depth 1 --quiet "https://github.com/$1.git" "$dir"
  echo "$dir"
}
place() { # place owner/repo path-in-repo skill-name
  local src; src="$(fetch "$1")/$2"
  if [ ! -d "$src" ]; then echo "  Skipped $3 (not found in $1)"; return; fi
  if [ -e "$TARGET/$3" ]; then echo "  Kept your existing $3"; return; fi
  cp -R "$src" "$TARGET/$3"; echo "  Installed $3 from $1"
}

echo
echo "Companion skills come from their authors' GitHub repos. Read them before you trust them."
if command -v git >/dev/null 2>&1 && yesno 'Download companion skills and the design library now?' y; then
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP" 2>/dev/null || true' EXIT
  if [ -d "$TARGET/website-builder/library/design-md" ]; then
    echo "  Design library already installed"
  elif yesno '  Design library: 70+ real brand DESIGN.md files (VoltAgent/awesome-design-md)' y; then
    lib="$(fetch VoltAgent/awesome-design-md)/design-md"
    mkdir -p "$TARGET/website-builder/library"
    rm -rf "$TARGET/website-builder/library/design-md"
    cp -R "$lib" "$TARGET/website-builder/library/design-md"; echo "  Installed design library"
  fi
  if yesno '  Design and testing (anthropics/skills: frontend-design, webapp-testing)' y; then
    place anthropics/skills skills/frontend-design frontend-design
    place anthropics/skills skills/webapp-testing webapp-testing
  fi
  if yesno '  Motion and anti-slop (AThevon/genjutsu: tells, motion-principles, css-native, desktop-principles)' y; then
    for s in tells motion-principles css-native desktop-principles; do place AThevon/genjutsu "skills/_jutsu/$s" "$s"; done
  fi
  if yesno '  Accessibility review (vercel-labs/agent-skills: web-design-guidelines)' y; then
    place vercel-labs/agent-skills skills/web-design-guidelines web-design-guidelines
  fi
  if yesno '  Speed (addyosmani/web-quality-skills: core-web-vitals, performance)' y; then
    place addyosmani/web-quality-skills skills/core-web-vitals core-web-vitals
    place addyosmani/web-quality-skills skills/performance performance
  fi
  if yesno '  Playwright tests (currents-dev/playwright-best-practices-skill)' n; then
    place currents-dev/playwright-best-practices-skill playwright-best-practices playwright-best-practices
  fi
  if yesno '  Cloudflare deploy (cloudflare/skills: wrangler, workers-best-practices)' n; then
    place cloudflare/skills skills/wrangler wrangler
    place cloudflare/skills skills/workers-best-practices workers-best-practices
  fi
  if yesno '  Skill safety check (NVIDIA/SkillSpector: skill-inspector)' y; then
    place NVIDIA/SkillSpector skills/skill-inspector skill-inspector
    echo "    The scanner itself is a separate install. If you have uv:"
    echo "    uv tool install --python 3.13 git+https://github.com/NVIDIA/skillspector.git"
  fi
  if yesno '  Video to notes (willmottjack11-bot/video-to-skill; needs its own setup and API keys for some videos)' n; then
    src="$(fetch willmottjack11-bot/video-to-skill)"
    if [ -e "$TARGET/video-to-skill" ]; then echo "  Kept your existing video-to-skill"
    else mkdir -p "$TARGET/video-to-skill" && cp -R "$src"/. "$TARGET/video-to-skill"/ && rm -rf "$TARGET/video-to-skill/.git" && echo "  Installed video-to-skill (run its setup on first use)"; fi
  fi
else
  echo "  Skipped companions. The skill still works using its own reference files."
fi

echo
echo "Optional progress bar mod (savvy-progress): see"
echo "  https://github.com/JohnnyVizz/claude-kit/tree/main/plugins/savvy-progress"
echo
echo "Done. Start a new Claude Code chat and say: build me a website"
