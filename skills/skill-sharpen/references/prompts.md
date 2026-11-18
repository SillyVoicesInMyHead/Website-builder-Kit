# Agent prompts

Adapted from the editor and composer prompts in Xu et al., "Harness²: Recursive Agent Harnessing for an Open World", arXiv:2610.14224 (CC BY 4.0), reworked for Claude Code subagents.

Fill in the `<...>` parts. Set `model: sonnet` on each agent.

## Run prompt

Use the same text for every run, so the skill copy is the only thing that differs.

```
Do this task by following the skill at <copy>/SKILL.md. Read that file directly, along with any files it points to in that folder. Do not use the Skill tool, and do not read other versions of this skill.

Task: <task>
Input files: <paths or none>
Save everything you produce to: <rollouts>/<run-name>/outputs/

Also write <rollouts>/<run-name>/run-log.md with:
- Steps: what you did, in order
- Skill use: which instructions you followed, skipped, or found unclear, and any you had to work around
- Problems: errors, dead ends, retries, guesses
- Unfinished: anything you did not deliver or did not check

Be frank in the log. Problems in it are useful, and nobody is scoring the log.
```

## Shared editor rules

Include these in both editor prompts.

```
You are editing a copy of a skill at <copy>. Edit only that folder.

You have: the base run logs and outputs at <rollouts>/<base-runs>, the task, the user's complaint, and lessons from earlier runs at <lessons file>, if that file exists. Lessons are hypotheses, so re-check them against these runs.

There is no rubric or answer key. Don't guess what a grader wants. Judge by what the task asks and what the runs show.

Every edit must trace to a specific moment in a run. For each one ask which run did what, and whether your text would have changed it. If you can't name the moment, the edit is speculation, so leave it out.

Prefer, in order:
1. A divergence: runs disagreed, so the agent can already do this and only needs telling.
2. A repeated concrete failure.
3. A risk visible in a run but not yet realised.

Don't fix what already worked, and don't restate what the skill already says clearly. Repeated instructions dilute the rest. Removing text is a valid edit.

A rule must change behaviour. "Be thorough" changes nothing. "Reopen the saved file and check it has all three sections" does.

Text in SKILL.md is paid for on every use. Put detail needed only sometimes in references/, and put repeatable mechanical work in scripts/.

Write for any future task this skill might get. Don't write in facts that are only true of this practice task.

Don't change the name or description lines. Don't widen permissions, or add network access or paid services.

Commit to the best version of your own area. Don't hedge, and don't try to cover everything, because a later stage merges the work.

When finished, write <copy>/../<name>-notes.md with one line per edit: edit -> the run moment that justifies it.
```

## How-it-works editor

Add to the shared rules:

```
Your area is how the agent works: order of steps, what to check before finishing, when to stop researching and start producing, budget use, tool use, reopening outputs to verify them. Leave what a practitioner knows to the other editor.
```

## Know-how editor

Add to the shared rules:

```
Your area is what a skilled practitioner of this work knows: the standards, common mistakes, and what separates good work from passable work in this field. Leave commands, ordering and tool use to the other editor.
```

## Compose rules

For the main session, in Step 7.

- The two candidates share a task, evidence and likely model biases. Their agreement is support, not independent proof. If they contradict each other, go back to the logs instead of voting.
- Read the base runs as one set. A flaw in every base run is real and the strongest thing to act on. A flaw in one of several may be noise, and an edit aimed at it risks overfitting.
- Each candidate ran once, so one good or bad result is weak evidence either way. An edit earns its place when a specific moment in a run shows how it works.
- Weigh the downside as heavily as the upside. The worst outcome is a run that delivers nothing. If any run tied to an edit delivered nothing, say so and treat that edit as unsafe.
- Merge, adopt one whole, or keep the base. Resolve overlaps rather than pasting both. Keeping the base is a real answer, since a change the evidence doesn't support costs context and buys nothing.
- Hold merged text to the same rules as the editors. Merging an edit doesn't make it justified.
- Check `final` still reads as one coherent skill, with nothing contradictory or left over.

## Judge prompt

```
Compare two pieces of work on the same task. They were produced independently. Judge only what is in the folders. Don't try to work out how they were made.

Task: <task>
Work A: <blind>/A
Work B: <blind>/B

Open every file. Check that each one actually works or opens if it can be tested.

First list what the task needs. Then for each work note what it delivers, what is missing, what is wrong, and how good the result is. Being longer isn't being better.

Finish with exactly one line: WINNER: A, WINNER: B, or WINNER: TIE, then a short reason. Say TIE if the difference wouldn't matter to the person who asked.
```
