#!/usr/bin/env python3
"""
SillyTavern chat completion preset (.json) → plm jsonl

plm record schema: {"role": ..., "content": ...}

Usage:
    st2plm.py preset.json > out.jsonl
    st2plm.py preset.json --include-markers --include-disabled

Notes:
- Only prompts whose entry in `prompt_order[*].order` has enabled=true are
  emitted, unless --include-disabled.
- Marker prompts (chatHistory, charDescription, worldInfo*, etc.) have no
  literal `content`; by default they're skipped. With --include-markers
  they're emitted as content="[[MARKER:<identifier>]]" so you can see where
  they would have been spliced.
- `assistant_prefill` (if non-empty) is appended last with role=assistant,
  which matches how SillyTavern actually sends it to the API.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator

def build_records(
    preset: dict,
    *,
    character_id: int | None = None,
    include_markers: bool = False,
    include_disabled: bool = False,
) -> Iterator[dict]:
    prompts_by_id = {p["identifier"]: p for p in preset.get("prompts", [])}

    orders = preset.get("prompt_order", [])
    if not orders:
        raise SystemExit("err: preset has no prompt_order")

    order_entry = orders[0]
    if character_id is not None:
        for o in orders:
            if o.get("character_id") == character_id:
                order_entry = o
                break
        else:
            raise SystemExit(f"err: character_id {character_id} not found")

    for item in order_entry.get("order", []):
        ident = item["identifier"]
        enabled = item.get("enabled", True)
        if not enabled and not include_disabled:
            continue

        prompt = prompts_by_id.get(ident)
        if prompt is None:
            print(f"warn: identifier {ident} not in prompts table", file=sys.stderr)
            continue

        role = prompt.get("role", "system")
        if prompt.get("marker"):
            if not include_markers:
                continue
            content = f"[[MARKER:{ident}]]"
        else:
            content = prompt.get("content", "")
            if not content.strip():
                # empty prompt slot; skip silently
                continue

        yield {"role": role, "content": content}

    prefill = preset.get("assistant_prefill", "")
    if prefill.strip():
        yield {"role": "assistant", "content": prefill}


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("preset", type=Path, help="SillyTavern preset .json")
    ap.add_argument("--character-id", type=int, default=None,
                    help="pick a specific prompt_order entry (default: first)")
    ap.add_argument("--include-markers", action="store_true",
                    help="emit marker prompts as [[MARKER:id]] placeholders")
    ap.add_argument("--include-disabled", action="store_true",
                    help="emit prompts even if enabled=false")
    args = ap.parse_args()

    preset = json.loads(args.preset.read_text(encoding="utf-8"))

    for rec in build_records(
        preset,
        character_id=args.character_id,
        include_markers=args.include_markers,
        include_disabled=args.include_disabled,
    ):
        json.dump(rec, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")


if __name__ == "__main__":
    main()
