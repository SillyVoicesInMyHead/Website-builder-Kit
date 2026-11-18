# Website Builder Kit

A Claude Code skill that builds websites that don't look AI-made, plus two helper skills and
an installer that sets it up with the companion skills it works best with.

## What you get

- **website-builder**: asks once what languages and look you want, then runs the job through
  copy, look, build, motion, phone, accessibility, a screenshot check and launch. It can do
  cinematic, Apple-style scroll storytelling, clone-then-rebrand from a reference site, or a
  look based on a real brand's design file. It reads only what each step needs, so it's light
  on tokens, and it respects the limits you set at install (helper agents, session size).
- **skill-sharpen**: improves any skill by testing competing edits and comparing results blind.
- **usage-audit**: shows where your Claude Code tokens went, from your local logs.

Optional companions the installer can fetch from their authors' repos (each one is asked
separately): Anthropic's `frontend-design` and `webapp-testing`, genjutsu's `tells`,
`motion-principles`, `css-native` and `desktop-principles`, Vercel's `web-design-guidelines`,
`core-web-vitals` and `performance`, Playwright best practices, Cloudflare's `wrangler` and
`workers-best-practices`, NVIDIA's `skill-inspector` (skill safety check), `video-to-skill`, and a
library of 70+ real brand `DESIGN.md` files. Sources and licenses are listed in
[`skills/website-builder/references/library-map.md`](skills/website-builder/references/library-map.md).
The skill still works without any of them.

## Install

You need [Claude Code](https://docs.claude.com/en/docs/claude-code) and, for the companions, `git`.

**Windows (PowerShell)**

```powershell
git clone https://github.com/SillyVoicesInMyHead/Website-builder-Kit.git
cd Website-builder-Kit
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**macOS / Linux**

```bash
git clone https://github.com/SillyVoicesInMyHead/Website-builder-Kit.git
cd Website-builder-Kit
bash install.sh
```

The installer:

1. Copies the three skills into `~/.claude/skills` (backing up any existing copies).
2. Asks for your settings and saves them to `~/.claude/skills/website-builder/config.json`:

   | Setting | Default | What it does |
   |---|---|---|
   | Most helper agents at once | 3 | 0 means Claude does everything itself |
   | Session size | normal | `small` reads the least and does one check pass; `large` reads companion skills in full |
   | Handoff at the end | yes | Offers a summary and a fresh chat when the site is done |
   | Write a README for the site | yes | Each finished site gets run, edit and deploy notes |
   | Models for helper agents | haiku (reading), sonnet (code) | |
   | Screenshots in the check | yes | |

   Deploying or pushing always asks first, whatever you set.
3. Asks which companion skills to download, one group at a time.

Options: `-Yes` / `--yes` accepts all defaults without asking. `-Target` / `--target` installs
somewhere else, for example `~/.agents/skills` for Codex.

To change settings later, run the installer again or edit `config.json`.

## Use

Start a new Claude Code chat and say something like:

- "build me a website for my bakery"
- "make a landing page for my app, Apple-style scroll"
- "redesign this page, it looks generic"

Claude asks a few quick questions at the start, then works without stopping until there's
something to show you.

## Optional: progress bar

If you split work across agents, the [savvy-progress](https://github.com/JohnnyVizz/claude-kit/tree/main/plugins/savvy-progress)
mod shows a progress bar and an agents panel. The skill uses it when it's there.

## Uninstall

Delete the folders from `~/.claude/skills`: `website-builder`, `skill-sharpen`, `usage-audit`,
and any companions you added.

## License

MIT for the files in this repo. Companion skills keep their own licenses.
