#!/usr/bin/env python3
"""Keyword Discovery via Amazon Suggest API. Zero cost, zero risk."""
import urllib.request, json, sys, time, os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    from catalog import save_data, catalog_path
except ImportError:
    save_data = None
    catalog_path = lambda: "(catalog unavailable)"


def suggest(prefix, market="com"):
    url = f"https://completion.amazon.{market}/api/2017/suggestions?mid=ATVPDKIKX0DER&alias=aps&prefix={urllib.request.quote(prefix)}"
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            return [s["value"] for s in json.loads(r.read()).get("suggestions", [])]
    except Exception:
        return []


def expand(seed, depth=3, market="com"):
    """Multi-level keyword expansion."""
    all_kw = set([seed])
    tree = {seed: []}

    l1 = suggest(seed, market)
    tree[seed] = l1
    all_kw.update(l1)

    if depth >= 2:
        for kw in l1[:8]:
            l2 = suggest(kw, market)
            tree[kw] = l2
            all_kw.update(l2)
            if depth >= 3:
                for kw2 in l2[:3]:
                    l3 = suggest(kw2, market)
                    tree[f"{kw} > {kw2}"] = l3
                    all_kw.update(l3)
            time.sleep(0.15)

    return {"seed": seed, "depth": depth, "total": len(all_kw), "keywords": sorted(all_kw), "tree": tree}


if __name__ == "__main__":
    seed = sys.argv[1] if len(sys.argv) > 1 else "yoga mat"
    depth = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    do_save = "--no-save" not in sys.argv

    result = expand(seed, depth)
    print(json.dumps({"total": result["total"], "keywords": result["keywords"]}, ensure_ascii=False, indent=2))
    print(f"\n{result['total']} keywords from '{seed}' at depth {depth}", file=sys.stderr)

    if do_save and save_data:
        fpath = save_data("kw-discover", result, {"seed": seed, "depth": depth})
        print(f"Saved: {fpath}", file=sys.stderr)
    elif do_save:
        print("(catalog module not found, data not saved to disk)", file=sys.stderr)
