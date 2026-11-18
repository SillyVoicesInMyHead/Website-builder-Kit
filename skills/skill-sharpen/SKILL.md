---
name: skill-sharpen
description: "Improve an existing Claude Code skill by evidence instead of guesswork: run it on a real task, draft competing edits, test them in fresh agents, blind-compare the outputs, and keep a change only if it wins. Keeping the original is a valid result. Use whenever the user says a skill keeps disappointing, gives weak or generic output, should be sharpened, tuned, tested, or made better, or asks to let a skill improve itself, even if they don't name this skill. Use skill-creator instead to build a new skill or tune when a skill triggers."
---

# Skill sharpen

Improve one existing skill by trying changes and keeping only what the evidence supports. The method adapts Harness² (see Sources) to Claude Code, with no Linux or cloud setup.

The honest expectation matters. In the paper, Opus 5's average gains were 3 to 5.5 points and the 100/100 results were picked examples. Many runs should end with small edits, or with no edit. A run that keeps the original has still done its job.

## Step 1: Pin down the job

Get these from the conversation, and ask only for what's missing:

- **Target skill:** its folder. Usually `~/.claude/skills/<name>`.
- **Practice task:** one real task the skill should do well, with any input files.
- **What was disappointing:** the user's own words. This is context for the editors, never a grading key.
- **Who judges:** see the table below.

| Output type | Judge |
|---|---|
| Checkable (data, code, a fixed format) | A fresh blind judge agent, plus any checks that can be scripted |
| Taste (voice, design, "sounds like AI") | The user, picking blind between A and B |

Don't let an agent settle a taste question alone. Agents share the blind spots that made the output feel generic, so the user is the only independent judge there.

If the target skill costs money per run (paid APIs, for example `video-to-skill`), say so before going further.

## Step 2: State the budget, then wait for a yes

| Level | Base runs | Editors | Trial runs | Final run | Second-task check | Judge | Agents |
|---|---|---|---|---|---|---|---|
| Quick (default) | 1 | 2 | 2 | 1 | none | 1 | 7 |
| Normal | 2 | 2 | 2 | 1 | 2 runs | 1 | 10 |

The judge agent drops out when the user is the judge. Normal needs a second, different task.

Every level uses several agents, so always say the agent count, the level and why, then wait for a yes (if `website-builder/config.json` sets `max_agents`, say whether the level fits it). Offer Normal when the skill gets heavy use, because Quick can't show that a change works beyond its one practice task.

Run agents in this chat with the Agent tool, leave effort unset, and set `model: sonnet` on runs, editors and the judge. Use Opus only if the user asks. Don't start separate sessions.

## Step 3: Set up the lab

```
python "<this skill's folder>/scripts/lab.py" init "<target skill folder>"
```

It prints JSON with the lab path, the four copies (`base`, `inv`, `dom`, `final`), the rollouts folder and the lessons file. Secrets such as `.env` are never copied, so note any run that fails for lack of a key.

Read the lessons file if it exists. Treat its entries as hypotheses to re-check against this run. A lesson from an older task is a lead, not a fact.

The target skill stays untouched until Step 9. All edits happen in the lab copies.

## Step 4: Base runs

Run the base copy on the practice task. Use the run prompt in `references/prompts.md` for every run in this skill.

Each run gets the path to one copy and reads that `SKILL.md` directly. It must not call the Skill tool, because that loads the installed version and the test would silently measure the wrong thing.

Each run also writes `run-log.md` beside its outputs. The Agent tool only returns a summary, and these logs are the evidence the editors work from. A log is self-reported, so if it conflicts with the outputs, believe the outputs, and measure any number before relying on it. For a suspicious run, read its session file under `~/.claude/projects/` as well.

Stop if the base run delivers nothing usable. That's a broken skill or a bad task, not something to tune.

## Step 5: Two competing editors

Start two editors in the same message. Prompts are in `references/prompts.md`.

- **How-it-works editor** (edits `inv`): procedure, ordering, checks, stopping, budget use, tool use.
- **Know-how editor** (edits `dom`): what a skilled practitioner of this work would know.

Keep them separate and don't show them each other's work. In the paper, replacing the two scoped editors with generic ones cost 2.9 and 3.7 points on the two benchmarks tested.

They may edit `SKILL.md`, `references/` and `scripts/`. They may not change the `name` or `description` lines, widen permissions, or add network access or new paid services. Trigger tuning belongs to skill-creator.

## Step 6: Trial runs

Run `inv` and `dom` once each on the practice task, in the same message. Then check both edits:

```
python "<this skill's folder>/scripts/lab.py" diff "<lab>" inv
python "<this skill's folder>/scripts/lab.py" diff "<lab>" dom
```

A `BLOCKED` line means the edit touched something off limits. Revert that part. Also look at the word count change, since every added word in `SKILL.md` is paid for on each use.

## Step 7: Compose

Do this yourself, in this chat. Read the base logs, both trial logs and both diffs, then write the result into `final`. Rules are in `references/prompts.md`, and the short form is:

- Choose one: merge both, adopt one whole, or keep the base.
- Every edit needs a named moment in a log that shows why. "Looks like good practice" isn't evidence.
- One good trial is weak evidence. A flaw repeated across base runs is strong evidence. A flaw seen once may be noise.
- Treat any edit tied to a run that delivered nothing as unsafe.

Record each decision in `<lab>/decisions.md` as `kept|revised|dropped -> edit -> evidence`.

If you keep the base, skip to Step 9 and report it.

## Step 8: Final comparison

Run `final` once on the practice task, then blind the two results:

```
python "<this skill's folder>/scripts/lab.py" blind "<lab>" <base-rollout> <final-rollout>
```

This puts the outputs in folders `A` and `B` in random order, without the run logs, and prints a comparison id. Do not read the key yet.

- **Agent judge:** give a fresh agent the task and folders `A` and `B`. Use the prompt in `references/prompts.md`, or skill-creator's `agents/comparator.md` if you can find it. Tell it nothing about what changed.
- **User judge:** show both outputs as A and B and ask which is better and why. Don't hint.

Reveal only after the verdict:

```
python "<this skill's folder>/scripts/lab.py" reveal "<lab>" <id>
```

For Normal, repeat the base and final runs on the second task and blind them too. `final` has to win or tie on both tasks. Never feed the second task back to the editors, or it stops being an independent check.

If `final` loses, or wins only by delivering less, keep the base.

## Step 9: Report, and adopt only on a yes

Report in plain words:

- The result: adopt, or keep the original.
- What the judge said, and how many comparisons were run. One comparison is thin evidence, so say so. Don't present results as scores.
- The diff, with the word count change.
- Anything not tested, such as "works beyond this one task" on Quick.

Ask for a yes before changing the installed skill. On a yes:

```
python "<this skill's folder>/scripts/lab.py" adopt "<lab>"
```

It backs up the skill, refuses if the installed skill changed since Step 3, and leaves files it never copied alone. To undo:

```
python "<this skill's folder>/scripts/lab.py" restore "<lab>"
```

## Step 10: Save lessons

Run `reveal` and read the key before writing anything here, so no lesson rests on a guess about who won. Add to the lessons file only what this run showed and a later run could use: what was weak, which change helped or failed, and the evidence. Failed changes are worth recording too. If nothing general was learned, add nothing. Keep each entry to a few lines, dated.

## Sources

- Xu et al., "Harness²: Recursive Agent Harnessing for an Open World", arXiv:2610.14224, CC BY 4.0. Propose, probe and compose, the two-editor split, and experience libraries come from here.
