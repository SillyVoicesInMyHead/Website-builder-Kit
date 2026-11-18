import argparse
import json
import sys
import time
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"
REPORTS = Path.home() / ".claude" / "usage-reports"
AGENT_GATE = 3


def local_day(stamp):
    return datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone().strftime("%Y-%m-%d")


def read_rows(path, since_day):
    rows = {}
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if '"usage"' not in line:
                continue
            try:
                row = json.loads(line)
            except ValueError:
                continue
            message = row.get("message")
            if not isinstance(message, dict) or not message.get("usage") or not row.get("timestamp"):
                continue
            day = local_day(row["timestamp"])
            if day < since_day:
                continue
            key = row.get("requestId") or message.get("id") or row.get("uuid")
            rows[key] = (day, row, message)
    return rows.values()


def blank():
    return {"input": 0, "cache_write": 0, "cache_read": 0, "output": 0, "thinking": 0, "calls": 0, "sidechain": 0}


def add(bucket, row, usage):
    bucket["input"] += usage.get("input_tokens") or 0
    bucket["cache_write"] += usage.get("cache_creation_input_tokens") or 0
    bucket["cache_read"] += usage.get("cache_read_input_tokens") or 0
    bucket["output"] += usage.get("output_tokens") or 0
    bucket["thinking"] += (usage.get("output_tokens_details") or {}).get("thinking_tokens") or 0
    bucket["calls"] += 1
    bucket["sidechain"] += 1 if row.get("isSidechain") else 0


def total(bucket):
    return bucket["input"] + bucket["cache_write"] + bucket["cache_read"] + bucket["output"]


def pct(part, whole):
    return f"{100 * part / whole:.1f}%" if whole else "0.0%"


def human(count):
    for unit, size in (("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if count >= size:
            return f"{count / size:.1f}{unit}"
    return str(count)


def main():
    parser = argparse.ArgumentParser(description="Summarise Claude Code token usage from local session logs.")
    parser.add_argument("--days", type=int, default=1, help="Days back to include, today counted as 1.")
    parser.add_argument("--top", type=int, default=5)
    parser.add_argument("--no-save", action="store_true")
    args = parser.parse_args()
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")

    since_day = (datetime.now() - timedelta(days=args.days - 1)).strftime("%Y-%m-%d")
    cutoff = time.time() - (args.days + 1) * 86400
    files = [p for p in PROJECTS.rglob("*.jsonl") if p.stat().st_mtime >= cutoff]

    grand = blank()
    by_day = defaultdict(blank)
    by_model = defaultdict(blank)
    by_session = defaultdict(blank)
    session_project = {}
    for path in files:
        for day, row, message in read_rows(path, since_day):
            usage = message["usage"]
            session = row.get("sessionId") or path.stem
            session_project[session] = path.relative_to(PROJECTS).parts[0][-40:]
            for bucket in (grand, by_day[day], by_model[message.get("model") or "?"], by_session[session]):
                add(bucket, row, usage)

    grand_total = total(grand)
    lines = [f"# Claude usage, last {args.days} day(s) to {datetime.now():%Y-%m-%d %H:%M}", ""]
    if not grand_total:
        lines.append("No usage rows found in that window.")
    else:
        lines += [
            f"Total: {human(grand_total)} tokens over {grand['calls']} calls in {len(files)} log files.",
            f"- Re-read from cache: {pct(grand['cache_read'], grand_total)}",
            f"- Cache writes: {pct(grand['cache_write'], grand_total)}",
            f"- Fresh input: {pct(grand['input'], grand_total)}",
            f"- Output (answers, code, thinking): {pct(grand['output'], grand_total)}"
            f" (thinking {human(grand['thinking'])})",
            f"- Calls made by subagents: {grand['sidechain']} of {grand['calls']}"
            f" ({pct(grand['sidechain'], grand['calls'])})",
            "",
            "## By day",
        ]
        for day in sorted(by_day):
            lines.append(f"- {day}: {human(total(by_day[day]))}, {by_day[day]['calls']} calls")
        lines += ["", "## By model"]
        for model, bucket in sorted(by_model.items(), key=lambda kv: -total(kv[1])):
            lines.append(f"- {model}: {human(total(bucket))}, {bucket['calls']} calls")
        lines += ["", f"## Top {args.top} sessions"]
        ranked = sorted(by_session.items(), key=lambda kv: -total(kv[1]))[: args.top]
        for session, bucket in ranked:
            lines.append(
                f"- {session[:8]} {session_project[session]}: {human(total(bucket))}, {bucket['calls']} calls,"
                f" {bucket['sidechain']} subagent calls, cache re-read {pct(bucket['cache_read'], total(bucket))}"
            )
        flags = []
        if grand["cache_read"] / grand_total > 0.9:
            flags.append("Over 90% of tokens are old context re-sent each turn. Start fresh chats sooner or lower the compact window.")
        if grand["sidechain"] > AGENT_GATE * 20:
            flags.append(f"{grand['sidechain']} subagent calls. Check that big fan-outs were asked about first.")
        for session, bucket in ranked[:1]:
            if total(bucket) > 0.5 * grand_total and len(by_session) > 1:
                flags.append(f"One session ({session[:8]}) used over half of everything.")
        lines += ["", "## Flags"] + ([f"- {flag}" for flag in flags] or ["- None."])

    text = "\n".join(lines)
    print(text)
    if not args.no_save:
        REPORTS.mkdir(parents=True, exist_ok=True)
        (REPORTS / f"{datetime.now():%Y-%m-%d}.md").write_text(text + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
