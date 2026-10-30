#!/usr/bin/env python3
"""Relay scorecard: compute first/final scores and keep a shared log.

  score.py add '<json with the raw counts>'   compute scores, append to the log, print the row
  score.py summary                            per model x size averages and recent trend

Log: $RELAY_SCORES or ~/.claude/relay-scores.jsonl. Formulas: references/scoring.md.
"""
import json
import os
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path

LOG = Path(os.environ.get("RELAY_SCORES", Path.home() / ".claude" / "relay-scores.jsonl"))
REQUIRED = ["project", "task", "workflow", "executor", "model", "t_total", "t_pass_first",
            "r_high", "r_mid", "r_low", "rework_rounds", "violations", "false_claims",
            "evidence_ratio", "final_pass"]


# 用户叫法 → 工具里的模型名；add 写入前和 summary 分组前都会统一
ALIASES = {"6.1sol": "gpt-6.1-sol", "6.1 sol": "gpt-6.1-sol", "sol": "gpt-6.1-sol",
           "6.1terra": "gpt-6.1-terra", "6.1 terra": "gpt-6.1-terra", "terra": "gpt-6.1-terra"}


def norm_model(m):
    return ALIASES.get(str(m).strip().lower(), m)


def size_of(t_total):
    return "S" if t_total <= 3 else "M" if t_total <= 8 else "L"


def first_score(r):
    s = 100.0
    s -= 30 * (1 - r["t_pass_first"] / r["t_total"])
    s -= min(30, 10 * r["r_high"] + 3 * r["r_mid"] + r["r_low"])
    s -= 15 * r["violations"] + 15 * r["false_claims"]
    s -= 10 * (1 - r["evidence_ratio"])
    return max(0, round(s))


def final_score(r):
    if not r["final_pass"]:
        return 0
    executor_rework = r["rework_rounds"] - r.get("rework_planner", 0)
    return max(0, 100 - 10 * executor_rework - 15 * r["violations"] - 15 * r["false_claims"])


def load():
    if not LOG.exists():
        return []
    return [json.loads(line) for line in LOG.read_text().splitlines() if line.strip()]


def add(raw):
    r = json.loads(raw)
    missing = [k for k in REQUIRED if k not in r]
    if missing:
        sys.exit(f"missing fields: {', '.join(missing)}")
    r.setdefault("rework_planner", 0)
    ints = ["t_total", "t_pass_first", "r_high", "r_mid", "r_low", "rework_rounds", "rework_planner",
            "violations", "false_claims"]
    bad = [k for k in ints if not isinstance(r[k], int) or isinstance(r[k], bool) or r[k] < 0]
    if bad:
        sys.exit(f"must be non-negative integers: {', '.join(bad)}")
    if r["t_total"] <= 0 or r["t_pass_first"] > r["t_total"]:
        sys.exit("need 0 < t_total and t_pass_first <= t_total")
    if r["rework_planner"] > r["rework_rounds"]:
        sys.exit("need rework_planner <= rework_rounds")
    if r["workflow"] == "relay-os" and r["executor"] != "claude-code":
        sys.exit("relay-os executor must be claude-code; external executors (grok, codex...) count as workflow relay")
    r["model"] = norm_model(r["model"])
    if not 0 <= r["evidence_ratio"] <= 1:
        sys.exit("evidence_ratio must be between 0 and 1")
    if not isinstance(r["final_pass"], bool):
        sys.exit("final_pass must be true or false")
    r.setdefault("date", date.today().isoformat())
    r.setdefault("size", size_of(r["t_total"]))
    r["first_score"] = first_score(r)
    r["final_score"] = final_score(r)

    peers = [x for x in load() if norm_model(x["model"]) == r["model"] != "unknown" and x["size"] == r["size"]]
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a") as f:
        f.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(json.dumps(r, ensure_ascii=False))
    if peers:
        avg_first = sum(x["first_score"] for x in peers) / len(peers)
        avg_final = sum(x["final_score"] for x in peers) / len(peers)
        print(f"history {r['model']} {r['size']}: first {avg_first:.0f} / final {avg_final:.0f} (n={len(peers)})")
        if r["first_score"] < avg_first - 15:
            print("WARNING first score is >15 below this model's average")
    else:
        print(f"history {r['model']} {r['size']}: none yet")


def summary():
    rows = load()
    if not rows:
        print("no records")
        return
    groups = defaultdict(list)
    for x in rows:
        groups[(norm_model(x["model"]), x["size"])].append(x)
    print("| model | size | n | first avg | final avg | last 5 first |")
    print("|---|---|---|---|---|---|")
    for (model, size), xs in sorted(groups.items()):
        xs.sort(key=lambda x: x.get("date", ""))
        f = sum(x["first_score"] for x in xs) / len(xs)
        g = sum(x["final_score"] for x in xs) / len(xs)
        trend = " ".join(str(x["first_score"]) for x in xs[-5:])
        note = "" if len(xs) >= 5 else " (n<5)"
        print(f"| {model} | {size} | {len(xs)}{note} | {f:.0f} | {g:.0f} | {trend} |")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "add":
        add(sys.argv[2])
    elif len(sys.argv) == 2 and sys.argv[1] == "summary":
        summary()
    else:
        sys.exit(__doc__)
