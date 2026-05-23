#!/usr/bin/env python3
"""Fixed BSR extraction assets for OpenClaw.

Use this file instead of ad-hoc prompt snippets:
  - `python3 scripts/bsr_runtime.py probe-js`
  - `python3 scripts/bsr_runtime.py extract-js`

It also contains lightweight HTML snapshot parsers so the extraction logic can be
tested locally without a live browser session.
"""

from __future__ import annotations

import html
import json
import os
import re
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROBE_JS_PATH = SCRIPT_DIR / "bsr_probe.js"
EXTRACT_JS_PATH = SCRIPT_DIR / "bsr_extract.js"
COLLECT_JS_PATH = SCRIPT_DIR / "bsr_collect.js"
EXPORT_JS_PATH = SCRIPT_DIR / "bsr_export.js"
RESET_JS_PATH = SCRIPT_DIR / "bsr_reset.js"


def probe_script() -> str:
    return PROBE_JS_PATH.read_text(encoding="utf-8")


def extract_script() -> str:
    return EXTRACT_JS_PATH.read_text(encoding="utf-8")


def collect_script() -> str:
    return COLLECT_JS_PATH.read_text(encoding="utf-8")


def export_script() -> str:
    return EXPORT_JS_PATH.read_text(encoding="utf-8")


def reset_script() -> str:
    return RESET_JS_PATH.read_text(encoding="utf-8")


def _extract_meta_blob(page_html: str) -> str:
    match = re.search(r'data-client-recs-list="(.*?)"\s+data-index-offset', page_html, re.S)
    return html.unescape(match.group(1)) if match else ""


def _extract_meta_ranks(page_html: str) -> list[str]:
    blob = _extract_meta_blob(page_html)
    return re.findall(r'"render\.zg\.rank":"(\d+)"', blob)


def probe_snapshot(page_html: str) -> dict:
    ranks = _extract_meta_ranks(page_html)
    rendered = len(re.findall(r'<div id="p13n-asin-index-\d+"[^>]*>.*?<div data-asin="', page_html, re.S))
    next_match = re.search(r'<li class="a-last"><a href="([^"]+)"', page_html)
    return {
        "expectedCount": len(ranks),
        "renderedCount": rendered,
        "isComplete": bool(ranks) and rendered == len(ranks),
        "firstExpectedRank": ranks[0] if ranks else "",
        "lastExpectedRank": ranks[-1] if ranks else "",
        "nextPageHref": html.unescape(next_match.group(1)) if next_match else "",
    }


def extract_snapshot(page_html: str) -> dict:
    items = []
    row_pattern = re.compile(
        r'<div id="p13n-asin-index-\d+"[^>]*>.*?<div data-asin="([^"]+)"[^>]*>(.*?)</div>\s*</div>\s*</div>\s*</span>\s*</li>',
        re.S,
    )
    for asin, block in row_pattern.findall(page_html):
        rank_match = re.search(r'<span class="zg-bdg-text">#(\d+)</span>', block)
        title_match = re.search(r'<img alt="([^"]*)"', block)
        price_match = re.search(r'(?:class="p13n-sc-price"|class="[^"]*p13n-sc-price[^"]*")>([^<]+)<', block)
        rating_match = re.search(r'aria-label="([^"]*out of 5 stars[^"]*)"', block)
        reviews_match = re.search(r'<span aria-hidden="true" class="a-size-small">([^<]+)</span>', block)
        items.append(
            {
                "rank": int(rank_match.group(1)) if rank_match else None,
                "asin": asin,
                "title": html.unescape(title_match.group(1)).strip() if title_match else "",
                "rating": html.unescape(rating_match.group(1)).strip() if rating_match else "",
                "reviews": html.unescape(reviews_match.group(1)).strip() if reviews_match else "",
                "price": html.unescape(price_match.group(1)).strip() if price_match else "",
            }
        )

    items.sort(key=lambda item: item["rank"] if item["rank"] is not None else 9999)
    return {
        "count": len(items),
        "firstRank": items[0]["rank"] if items else None,
        "lastRank": items[-1]["rank"] if items else None,
        "items": items,
    }


def empty_state() -> dict:
    return {
        "expectedCount": 0,
        "itemsByRank": {},
        "collectedCount": 0,
        "minCollectedRank": None,
        "maxCollectedRank": None,
        "isComplete": False,
    }


def merge_snapshot_into_state(state: dict, extracted: dict, probe: dict) -> dict:
    merged = {
        "expectedCount": max(state.get("expectedCount", 0), probe.get("expectedCount", 0)),
        "itemsByRank": dict(state.get("itemsByRank", {})),
    }
    for item in extracted.get("items", []):
        rank = item.get("rank")
        if rank is None:
            continue
        merged["itemsByRank"][str(rank)] = item

    items = sorted(merged["itemsByRank"].values(), key=lambda item: item.get("rank") or 9999)
    merged["collectedCount"] = len(items)
    merged["minCollectedRank"] = items[0]["rank"] if items else None
    merged["maxCollectedRank"] = items[-1]["rank"] if items else None
    merged["isComplete"] = bool(merged["expectedCount"]) and merged["collectedCount"] >= merged["expectedCount"]
    return merged


def build_test_fixture(expected_count: int, rendered_count: int, start_rank: int = 1) -> str:
    meta = []
    for rank in range(start_rank, start_rank + expected_count):
        meta.append(
            {
                "id": f"ASIN{rank:06d}",
                "metadataMap": {"render.zg.rank": str(rank)},
                "linkParameters": {},
            }
        )
    meta_attr = html.escape(json.dumps(meta, separators=(",", ":")), quote=True)

    rows = []
    for idx, rank in enumerate(range(start_rank, start_rank + rendered_count)):
        asin = f"ASIN{rank:06d}"
        rows.append(
            f'''
            <li class="zg-no-numbers"><span class="a-list-item">
              <div id="gridItemRoot" class="a-column a-span12 a-text-center _cDEzb_grid-column_2hIsc">
                <div id="p13n-asin-index-{idx}" class="a-cardui _cDEzb_grid-cell_1uMOS expandableGrid p13n-grid-content" data-a-card-type="basic">
                  <div data-asin="{asin}" class="_cDEzb_iveVideoWrapper_JJ34T">
                    <div class="a-section zg-bdg-ctr"><div class="a-section zg-bdg-body zg-bdg-clr-body aok-float-left"><span class="zg-bdg-text">#{rank}</span></div></div>
                    <div class="zg-grid-general-faceout"><span><div id="{asin}" class="p13n-sc-uncoverable-faceout">
                      <a aria-hidden="true" class="a-link-normal aok-block" tabindex="-1" href="/dp/{asin}">
                        <div class="a-section a-spacing-mini _cDEzb_noop_3Xbw5"><img alt="Product {rank}" src="https://example.com/{asin}.jpg"/></div>
                      </a>
                      <div><div>
                        <a class="a-link-normal aok-block" href="/dp/{asin}" role="link"><span><div class="_cDEzb_p13n-sc-css-line-clamp-3_g3dy1">Product {rank}</div></span></a>
                        <div class="a-row"><div class="a-icon-row"><a aria-label="4.5 out of 5 stars, {rank} ratings" class="a-link-normal"><span aria-hidden="true" class="a-size-small">{rank}</span></a></div></div>
                        <div class="a-row"><div class="a-row"><div class="_cDEzb_p13n-sc-price-animation-wrapper_3PzN2"><a class="a-link-normal aok-block a-text-normal" role="link"><div class="a-row"><span class="a-size-base a-color-price"><span class="_cDEzb_p13n-sc-price_3mJ9Z">${rank}.99</span></span></div></a></div></div></div>
                      </div></div>
                    </div></span></div>
                  </div>
                </div>
              </div>
            </span></li>
            '''
        )

    return f'''
    <html>
      <body>
        <div class="p13n-desktop-grid" data-client-recs-list="{meta_attr}" data-index-offset="30" data-offset="50">
          <ol class="a-ordered-list a-vertical p13n-gridRow _cDEzb_grid-row_3Cywl">
            {"".join(rows)}
          </ol>
          <nav aria-label="pagination" class="a-text-center">
            <ul class="a-pagination">
              <li class="a-last"><a href="/Best-Sellers/ref=zg_bs_pg_2?_encoding=UTF8&amp;pg=2">Next page</a></li>
            </ul>
          </nav>
        </div>
      </body>
    </html>
    '''


def _print_usage() -> int:
    print("Usage: bsr_runtime.py [reset-js|probe-js|extract-js|collect-js|export-js|probe-html PATH|extract-html PATH]")
    return 1


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        return _print_usage()

    cmd = argv[1]
    if cmd == "probe-js":
        print(probe_script())
        return 0
    if cmd == "reset-js":
        print(reset_script())
        return 0
    if cmd == "extract-js":
        print(extract_script())
        return 0
    if cmd == "collect-js":
        print(collect_script())
        return 0
    if cmd == "export-js":
        print(export_script())
        return 0
    if cmd in {"probe-html", "extract-html"}:
        if len(argv) < 3:
            return _print_usage()
        page_html = Path(argv[2]).read_text(encoding="utf-8")
        result = probe_snapshot(page_html) if cmd == "probe-html" else extract_snapshot(page_html)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    return _print_usage()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
