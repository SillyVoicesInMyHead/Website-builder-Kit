#!/usr/bin/env python3
"""Lab helper for skill-sharpen. Standard library only.

  lab.py init <skill_dir>            copy the skill into a new lab
  lab.py diff <lab> <copy>           show a copy's changes against base
  lab.py blind <lab> <run_a> <run_b> put two runs' outputs into random A/B
  lab.py reveal <lab> <id>           show which run was A and which B
  lab.py adopt <lab> [--copy final]  back up the skill, then apply a copy
  lab.py restore <lab>               put the backup back
"""
import argparse
import difflib
import filecmp
import json
import random
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

LAB_ROOT = Path.home() / ".claude" / "skill-sharpen"
COPIES = ("base", "inv", "dom", "final")
SKIP_NAMES = {".env", "__pycache__", ".git", ".venv", "node_modules", ".DS_Store"}
SKIP_SUFFIXES = (".pyc", ".log")


def skipped(rel):
    return any(p in SKIP_NAMES or p.startswith(".env") for p in rel.parts) or (
        rel.suffix in SKIP_SUFFIXES or ".bak" in rel.name
    )


def tracked(root):
    """Relative paths of the files we copy, leaving out secrets and junk."""
    root = Path(root)
    return sorted(
        p.relative_to(root)
        for p in root.rglob("*")
        if p.is_file() and not skipped(p.relative_to(root))
    )


def copy_files(src, dst, files):
    for rel in files:
        target = Path(dst) / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(Path(src) / rel, target)


def load_meta(lab):
    path = Path(lab) / "lab.json"
    if not path.exists():
        sys.exit(f"Not a lab folder: {lab}")
    return json.loads(path.read_text(encoding="utf-8"))


def read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8")
    except (UnicodeDecodeError, FileNotFoundError):
        return None


def frontmatter_field(text, field):
    """The field's value, including any indented continuation lines."""
    match = re.match(r"^---\r?\n(.*?)\r?\n---", text or "", re.S)
    if not match:
        return None
    found = re.search(
        rf"^{field}:.*(?:\r?\n[ \t].*)*", match.group(1), re.M
    )
    return found.group(0) if found else None


def cmd_init(args):
    skill = Path(args.skill_dir).expanduser().resolve()
    if not (skill / "SKILL.md").is_file():
        sys.exit(f"No SKILL.md in {skill}")
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    lab = LAB_ROOT / skill.name / stamp
    files = tracked(skill)
    for name in COPIES:
        copy_files(skill, lab / "copies" / name, files)
    (lab / "rollouts").mkdir(parents=True)
    meta = {"target": str(skill), "skill": skill.name, "created": stamp}
    (lab / "lab.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    left_out = [
        str(p.relative_to(skill))
        for p in skill.rglob("*")
        if p.is_file() and skipped(p.relative_to(skill))
    ]
    print(json.dumps({
        "lab": str(lab),
        "copies": {n: str(lab / "copies" / n) for n in COPIES},
        "rollouts": str(lab / "rollouts"),
        "lessons": str(LAB_ROOT / skill.name / "lessons.md"),
        "files_copied": len(files),
        "left_out": left_out,
    }, indent=2))


def cmd_diff(args):
    lab = Path(args.lab)
    load_meta(lab)
    base = lab / "copies" / "base"
    copy = lab / "copies" / args.copy
    if not copy.is_dir():
        sys.exit(f"No copy named {args.copy}")
    blocked = []
    changed = False
    for rel in sorted(set(tracked(base)) | set(tracked(copy))):
        a, b = base / rel, copy / rel
        if a.exists() and b.exists() and filecmp.cmp(a, b, shallow=False):
            continue
        changed = True
        if rel.parts[0] != "SKILL.md" and rel.parts[0] not in ("references", "scripts"):
            blocked.append(f"{rel}: outside SKILL.md, references/ and scripts/")
        ta, tb = read_text(a), read_text(b)
        if (a.exists() and ta is None) or (b.exists() and tb is None):
            print(f"Binary file changed: {rel}")
            continue
        sys.stdout.writelines(difflib.unified_diff(
            (ta or "").splitlines(True), (tb or "").splitlines(True),
            f"base/{rel}", f"{args.copy}/{rel}",
        ))
        print()
    if not (copy / "SKILL.md").exists():
        blocked.append("SKILL.md was removed")
    else:
        old, new = read_text(base / "SKILL.md"), read_text(copy / "SKILL.md")
        for field in ("name", "description"):
            if frontmatter_field(old, field) != frontmatter_field(new, field):
                blocked.append(f"the {field} line changed")
        before, after = len(old.split()), len(new.split())
        print(f"SKILL.md words: {before} -> {after} ({after - before:+d})")
    if not changed:
        print("No changes.")
    for line in blocked:
        print(f"BLOCKED: {line}")


def cmd_blind(args):
    lab = Path(args.lab)
    load_meta(lab)
    runs = [args.run_a, args.run_b]
    for run in runs:
        if not (lab / "rollouts" / run / "outputs").is_dir():
            sys.exit(f"No outputs folder for run {run}")
    random.shuffle(runs)
    blind_root = lab / "blind"
    blind_root.mkdir(exist_ok=True)
    cid = f"c{len(list(blind_root.glob('*.key.json'))) + 1}"
    folder = blind_root / cid
    for label, run in zip("AB", runs):
        shutil.copytree(lab / "rollouts" / run / "outputs", folder / label)
    # The key sits outside the folder handed to the judge.
    (blind_root / f"{cid}.key.json").write_text(
        json.dumps({"A": runs[0], "B": runs[1]}), encoding="utf-8"
    )
    print(json.dumps({
        "id": cid, "A": str(folder / "A"), "B": str(folder / "B")
    }, indent=2))


def cmd_reveal(args):
    key = Path(args.lab) / "blind" / f"{args.id}.key.json"
    if not key.exists():
        sys.exit(f"No comparison named {args.id}")
    print(key.read_text(encoding="utf-8"))


def cmd_adopt(args):
    lab = Path(args.lab)
    meta = load_meta(lab)
    target = Path(meta["target"])
    base = lab / "copies" / "base"
    copy = lab / "copies" / args.copy
    if not (copy / "SKILL.md").is_file():
        sys.exit(f"No SKILL.md in copy {args.copy}")
    base_files, copy_list = set(tracked(base)), set(tracked(copy))

    drift = [
        str(rel) for rel in base_files
        if not (target / rel).exists()
        or not filecmp.cmp(base / rel, target / rel, shallow=False)
    ]
    drift += [str(r) for r in set(tracked(target)) - base_files]
    if drift:
        sys.exit("The installed skill changed since init, so nothing was "
                 "applied: " + ", ".join(sorted(drift)))

    backup = lab / "backup"
    if backup.exists():
        sys.exit(f"A backup already exists at {backup}. Run restore first.")
    copy_files(target, backup, sorted(base_files))
    copy_files(copy, target, sorted(copy_list))
    for rel in base_files - copy_list:
        (target / rel).unlink()
    print(f"Adopted {args.copy} into {target}. Backup: {backup}")


def cmd_restore(args):
    lab = Path(args.lab)
    meta = load_meta(lab)
    target = Path(meta["target"])
    backup = lab / "backup"
    if not backup.is_dir():
        sys.exit("No backup in this lab.")
    backed_up = set(tracked(backup))
    for rel in set(tracked(target)) - backed_up:
        (target / rel).unlink()
    copy_files(backup, target, sorted(backed_up))
    shutil.move(str(backup), str(lab / f"backup-restored-{datetime.now():%H%M%S}"))
    print(f"Restored {target}.")


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawTextHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("init"); p.add_argument("skill_dir"); p.set_defaults(fn=cmd_init)
    p = sub.add_parser("diff"); p.add_argument("lab"); p.add_argument("copy"); p.set_defaults(fn=cmd_diff)
    p = sub.add_parser("blind"); p.add_argument("lab"); p.add_argument("run_a"); p.add_argument("run_b"); p.set_defaults(fn=cmd_blind)
    p = sub.add_parser("reveal"); p.add_argument("lab"); p.add_argument("id"); p.set_defaults(fn=cmd_reveal)
    p = sub.add_parser("adopt"); p.add_argument("lab"); p.add_argument("--copy", default="final"); p.set_defaults(fn=cmd_adopt)
    p = sub.add_parser("restore"); p.add_argument("lab"); p.set_defaults(fn=cmd_restore)
    args = parser.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
