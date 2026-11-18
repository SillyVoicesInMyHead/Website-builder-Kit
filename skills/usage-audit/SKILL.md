---
name: usage-audit
description: "Use when the user asks about token usage, hitting Claude limits, why a week used so many tokens, or at the start of the daily usage check. Runs a local script over the Claude Code session logs and reports where tokens went: re-read cache vs real output, subagent fan-out, top sessions."
---

# Usage audit

1. Run `python "<this skill's folder>/scripts/usage_audit.py" --days 1` (`python3` on macOS and Linux) (use `--days 7` for a week). It reads `~/.claude/projects/**/*.jsonl`, only files touched in the window, and saves a dated report to `~/.claude/usage-reports/`.
2. Read the Flags section. Report to the user in a few lines: total tokens, the cache re-read share, subagent call share, and the top session with its project.
3. If one session dominates, open that project's log and say what launched the subagents. Do not guess.
4. Offer fixes, one at a time, and apply none without a yes:
   - Start a fresh chat after a feature is done, after writing a handoff summary (decided, done, left, file names).
   - Lower the auto-compact window with `CLAUDE_CODE_AUTO_COMPACT_WINDOW` in the `env` block of `~/.claude/settings.json`. Documented range is 100000 to 1000000, plain integers only. Merge into the existing `env` block.
   - Run `/skill-doctor` in an interactive session to see per-skill token cost and unused skills (needs Claude Code 2.1.252 or later).
   - Use a cheaper model for routine work.

Numbers come from the logs, not from the plan's usage page, so they will not match it exactly. Say so if the user compares them. Source of the ranking: stilesdichter.com guide on Claude limits, the logs approach is the guide's, the script is local.
