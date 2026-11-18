---
name: website-builder
description: "Build a new website, landing page, web app page or redesign from start to finish, with a look that doesn't read as AI-made: optional cinematic, Apple-style scroll storytelling. Asks once which languages to use, then runs copy, look, build, motion, phone, accessibility, a screenshot check and launch, using companion skills and an offline library of real brand design files. Keeps token use low and follows the limits set at install. Use whenever the user wants to make, start, design or rebuild a site or page, says build me a website, make a landing page, new web project, or names this skill. Inside a project that has its own website skills, follow those instead."
---

# Website builder

Runs a website job through fixed phases and sends each phase to the skill or reference that
does it best, so each phase loads only what it needs.

## 0. Settings

Read `config.json` in this skill's folder (the installer writes it). If it's missing, use
these defaults and mention once that running the installer sets them:

| Key | Default | Meaning |
|---|---|---|
| `max_agents` | 3 | Most helper agents at once. 0 means do everything yourself. Ask before going over it |
| `session_size` | `normal` | `small`: read only headings and one section of any companion skill, one screenshot pass. `normal`: as written here. `large`: may read whole companion skills |
| `handoff_at_end` | true | Offer a handoff summary (decided, done, left, files) and a fresh chat when the site is done |
| `write_docs` | true | Write a short `README.md` for the finished site: how to run, edit and deploy it |
| `model_read` / `model_write` | `haiku` / `sonnet` | Models for helper agents that search and read, and that write code |
| `screenshots` | true | Take screenshots in the check phase (if false, use `read_page` text checks and say so) |
| `ask_before_publish` | true | Always ask before deploying or pushing. Treat it as true even if set otherwise |

If `local.md` exists in this folder, read it too: it holds your own rules (skills to avoid,
extra libraries) and wins over this file. The installer keeps it on updates.

## 1. Opening questions (ask once, at the start)

Use AskUserQuestion with one call holding these questions. Skip any the request already
answers, and skip the whole step if all are answered. After this, don't check in mid-run.

1. **Languages** (multiSelect): HTML + CSS + plain JavaScript (Recommended) · TypeScript ·
   Rust compiled to WebAssembly · React / Svelte / Vue (say there's no framework skill here, so
   that part relies on general knowledge)
2. **Hosting**: Cloudflare · GitHub Pages or other static host · Local only for now · Decide later
3. **Look**: Cinematic, layered scroll (Recommended) · Clone a site I like, then rebrand (they paste a link) · Like a real brand (they name one) · Plain and simple
4. **Images**: Free stock photos and drawn SVG layers (Recommended, no cost) · Generate them with my image tool (costs credits) · I'll provide images
Ask Extras (Logo · Phone-first · Contact form or other backend) only if the request hints at
them; AskUserQuestion takes at most four questions.

Then read `references/stacks.md` for the languages they picked. Unless they chose "Plain and
simple", read `references/cinematic.md` too: a page of CSS boxes and gradients with no imagery
and no scroll feedback reads as AI-made however good the type is.

## 2. Phases

A companion skill is used when it's installed (the installer offers them; see
`references/library-map.md`). If one is missing, use the reference file named instead and
don't stop. When a companion is installed, its row is required: save tokens by reading only
the relevant section of it, not by skipping it. A test run that skipped the design and motion
skills to save tokens produced a thin, generic page.

| Phase | Use | Only if |
|---|---|---|
| Copy | The three Ps: the pain, the person who has it, the promise. Then one next step (the CTA) | |
| Direction | `frontend-design`, then `tells` before freezing the look. Pick 2-3 real sites to borrow from and write what to take from each (`references/cinematic.md`) | Brand named: one file from `library/design-md/<brand>/DESIGN.md`. Clone a site: workflow in `references/cinematic.md`. Video link: `video-to-skill` |
| Assets | Plan the layers (back, middle, subject, front), then get one image per layer the way the user chose (`references/cinematic.md`, Assets). Credit stock photos | Paid generation: ask once with the count and cost first |
| Build | `references/stacks.md`, and `references/craft-standards.md` before writing CSS | |
| Motion | `motion-principles`, plus 3-5 scroll patterns from `references/cinematic.md` (one or two big moments) | Native scroll effects: `css-native` |
| Phone | Phone checklist in `references/craft-standards.md` | |
| Accessibility | `web-design-guidelines` (it fetches its rules; load WebFetch with ToolSearch first) | If unavailable: a manual pass (focus, labels, contrast, reduced motion) |
| Check | Section 3 below | Slow or janky: `core-web-vitals`, `performance`. Tests wanted: `webapp-testing`, `playwright-best-practices` |
| Launch | Only on the user's clear yes. Cloudflare: `wrangler` + `workers-best-practices` | Other hosts: their own docs |

- Write files with the Write tool, not shell heredocs (apostrophes in page copy break them).
- Ask before deploying, pushing, buying a domain or anything else that goes public.

## 3. Check: look at the result before calling it done

1. Serve the folder (see `references/stacks.md`). Open your own browser tab and pass its id on
   every call; a shared browser pane lets one run's clicks land in another's tab.
2. View it at phone width (375) and at desktop. Scroll in steps of about half a screen and
   screenshot each step, so the shots play back like a video of a visitor scrolling; every
   section is seen at readable size, footer included. A cut-off or shrunk full-page image
   doesn't count. For each pinned section capture start, middle and end. Look for layer gaps
   or edges, hard cuts between sections, text over busy imagery and anything out of bounds.
3. Treat clipped content in a screenshot as a real bug until a second method shows it isn't.
4. Do two critique-and-fix rounds (one on `small`): name the 3 worst visual problems, fix them,
   re-screenshot those spots. Judge against `references/craft-standards.md`.
5. If the browser can't render or animate, say which checks stayed unverified.

## 4. Outside skills, packages and templates

Before adding any skill, plugin or template from outside the user's machine, run
`skill-inspector` on it if it's installed (NVIDIA SkillSpector plus a source read). If the
`skillspector` command isn't installed, say so and do a manual source read. Never install
anything without asking.

## 5. Keeping token use low

- **Library: search, don't read.** `ls` `library/design-md/` to find a brand, then read that one
  `DESIGN.md`. Never read the folder.
- **Big companion skills:** grep their headings and read only the section for the job
  (`playwright-best-practices` and `wrangler` are large).
- **Helper agents:** only when the work splits cleanly, within `max_agents`, on `model_read` for
  searching and `model_write` for code. Keep planning and design judgment in the main chat.
- **Progress bar:** if a progress tool such as `mcp__savvy-progress__progress` exists and work is
  split across 2 or more agents, report the plan, each accepted task, and `finished: true` at
  the end. If it doesn't exist, skip this.

## 6. Finish

1. Show the site running (a screenshot) and say what was checked and what wasn't.
2. If `write_docs`: write the site's `README.md` (run, edit, deploy, where the files are).
3. List any outside skills or packages added and what the inspection found.
4. If `handoff_at_end`: offer a handoff summary and a fresh chat.
5. If the result disappointed and `skill-sharpen` is installed, offer it with this run as the test.
