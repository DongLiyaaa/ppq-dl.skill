"""
ppq-dl shared data catalog.

All helper scripts and OpenClaw-generated structured results should use this module
to manage local data persistence:
  - save_data(): 保存结构化 JSON 并注册到目录索引
  - list_runs(): 查询历史数据记录
  - catalog_path(): 返回目录文件路径

目录文件: ~/Documents/amazon-data/_catalog.json
"""
import os, json
from datetime import datetime

try:
    from config import OUTPUT_DIR
except ImportError:
    OUTPUT_DIR = os.environ.get("AMZ_OUTPUT_DIR", os.path.expanduser("~/Documents/amazon-data"))

CATALOG_FILE = os.path.join(OUTPUT_DIR, "_catalog.json")


def _load_catalog():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    if os.path.exists(CATALOG_FILE):
        with open(CATALOG_FILE) as f:
            try:
                return json.load(f)
            except json.JSONDecodeError:
                pass
    return {"created": datetime.now().isoformat(), "runs": []}


def _save_catalog(catalog):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with open(CATALOG_FILE, "w") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)


def save_data(data_type, data, metadata=None):
    """
    保存数据并注册到目录索引。

    参数:
      data_type: 数据类型标识 ("kw-discover", "kw-analyze", "product-intel", "bsr-scan", "rank-snapshot")
      data:      dict, 要保存的数据
      metadata:  dict, 附加元数据 (如 seed, asin, keywords, category)

    返回: 保存的文件路径
    """
    ts = datetime.now()
    stamp = ts.strftime("%Y%m%d_%H%M%S")
    fname = f"{data_type}-{stamp}.json"
    fpath = os.path.join(OUTPUT_DIR, fname)

    record = {
        "type": data_type,
        "timestamp": ts.isoformat(),
        "file": fname,
        "data": data,
    }
    if metadata:
        record["metadata"] = metadata

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with open(fpath, "w") as f:
        json.dump(record, f, ensure_ascii=False, indent=2)

    # 注册到目录
    cat = _load_catalog()
    entry = {
        "type": data_type,
        "timestamp": ts.isoformat(),
        "file": fname,
    }
    if metadata:
        entry["metadata"] = metadata
    cat["runs"].insert(0, entry)
    cat["updated"] = ts.isoformat()
    _save_catalog(cat)

    return fpath


def list_runs(data_type=None, limit=20):
    """
    列出历史数据记录。

    参数:
      data_type: 过滤类型 (None = 全部)
      limit:     最多返回条数

    返回: list[dict]
    """
    cat = _load_catalog()
    runs = cat.get("runs", [])
    if data_type:
        runs = [r for r in runs if r["type"] == data_type]
    return runs[:limit]


def catalog_path():
    """返回目录索引文件的完整路径。"""
    return CATALOG_FILE


def is_first_run():
    """检测是否为首次运行（数据目录不存在或无目录文件）。"""
    return not os.path.exists(CATALOG_FILE)


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "list":
        dtype = sys.argv[2] if len(sys.argv) > 2 else None
        limit = int(sys.argv[3]) if len(sys.argv) > 3 else 20
        runs = list_runs(dtype, limit)
        if runs:
            for r in runs:
                meta = r.get("metadata", {})
                label = meta.get("seed") or meta.get("asin") or meta.get("category") or ""
                print(f"{r['timestamp'][:19]}  {r['type']:16s}  {label[:40]}")
        else:
            print("(暂无数据记录)")
    elif len(sys.argv) > 1 and sys.argv[1] == "first-run":
        print("true" if is_first_run() else "false")
    else:
        print(f"Catalog: {CATALOG_FILE}")
        print(f"Runs: {len(_load_catalog().get('runs', []))}")
