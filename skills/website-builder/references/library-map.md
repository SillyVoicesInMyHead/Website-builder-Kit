# Library map

What the kit's installer can add next to `website-builder`, where each piece comes from, and
what the skill uses it for. Everything is optional: the skill falls back to its own reference
files when a companion is missing.

## Offline design library

| Folder | Source | Use |
|---|---|---|
| `library/design-md/<brand>/DESIGN.md` | [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md) (MIT) | How a real product sets type, colour, spacing and components. Read one brand at a time |

## Companion skills (installed into your skills folder)

| Skill | Source | License | Phase |
|---|---|---|---|
| frontend-design, webapp-testing | [anthropics/skills](https://github.com/anthropics/skills) | per skill folder (Apache-2.0) | Direction, Check |
| tells, motion-principles, css-native, desktop-principles | [AThevon/genjutsu](https://github.com/AThevon/genjutsu) | MIT | Direction, Motion |
| web-design-guidelines | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | see repo | Accessibility |
| core-web-vitals, performance | [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) | MIT | Check |
| playwright-best-practices | [currents-dev/playwright-best-practices-skill](https://github.com/currents-dev/playwright-best-practices-skill) | MIT | Check |
| wrangler, workers-best-practices | [cloudflare/skills](https://github.com/cloudflare/skills) | Apache-2.0 | Launch |
| skill-inspector | [NVIDIA/SkillSpector](https://github.com/NVIDIA/SkillSpector) | Apache-2.0 | Outside code check |
| video-to-skill | [willmottjack11-bot/video-to-skill](https://github.com/willmottjack11-bot/video-to-skill) | see repo | Direction (video references) |
| skill-sharpen, usage-audit | this kit | MIT | Improving skills, cost checks |

## Optional mod

| Mod | Source | Use |
|---|---|---|
| savvy-progress | [JohnnyVizz/claude-kit](https://github.com/JohnnyVizz/claude-kit/tree/main/plugins/savvy-progress) (MIT) | Progress bar and agents panel when work is split across agents. Install with that repo's instructions |
