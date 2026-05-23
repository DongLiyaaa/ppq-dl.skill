# 数据持久化规范

## 目录结构

```
~/Documents/amazon-data/
├── _catalog.json          ← 全局索引（所有数据文件的注册表）
├── kw-discover-{ts}.json  ← 关键词发现结果
├── kw-analyze-{ts}.json   ← 竞争分析结果
├── product-intel-{ts}.json← 产品情报结果
├── bsr-scan-{ts}.json     ← BSR 深度扫描结果
~/Documents/keyword-rankings/
└── ranking_history.json   ← 排名快照历史（跨天对比）
```

## 数据文件格式

### 统一外层结构

每个数据文件遵循统一格式：

```json
{
  "type": "kw-discover|kw-analyze|product-intel|bsr-scan|rank-snapshot",
  "timestamp": "2026-05-14T10:30:00",
  "file": "kw-discover-20260514_103000.json",
  "metadata": {
    "seed": "coffee maker",        // kw-discover
    "asin": "B01LP0U5X0",          // kw-analyze, product-intel
    "depth": 3,                    // kw-discover
    "keywordCount": 5,             // kw-analyze
    "category": "Kitchen & Dining" // bsr-scan
  },
  "data": { /* 各类型的实际数据 */ }
}
```

### 各类型 data 字段

| 类型 | data 内容 |
|------|----------|
| `kw-discover` | `{"seed":"...", "depth":3, "total":45, "keywords":["...",...], "tree":{...}}` |
| `kw-analyze` | `{"asin":"...", "keywords":{"kw1":{"position":3, "totalResults":1500, "avgReviews":320, "uniqueBrands":8, "ads":2, "di":34.5, ...}}}` |
| `product-intel` | `{"asin":"...", "data":{"title":"...", "price":"...", "rating":"...", "reviewCount":"...", "stock":"...", "bsr":[...], "carousels":[...]}}` |
| `bsr-scan` | `{"scanTime":"...", "category":"...", "categoryUrl":"...", "subcategoriesScanned":6, "totalUniqueAsins":171, "products":[...], "bsrDetails":{...}}` |
| `rank-snapshot` | 多 ASIN 历史文件，由 OpenClaw 调用 cdp-bridge MCP 抓取后写入 |

## 目录索引（_catalog.json）

```json
{
  "created": "2026-05-14T10:00:00",
  "updated": "2026-05-14T10:30:00",
  "runs": [
    {
      "type": "kw-discover",
      "timestamp": "2026-05-14T10:30:00",
      "file": "kw-discover-20260514_103000.json",
      "metadata": {"seed": "coffee maker", "depth": 3}
    }
  ]
}
```

每次 `save_data()` 调用自动在 `runs` 数组头部插入新记录。

## Python 脚本 API

所有脚本通过 `scripts/catalog.py` 统一管理持久化：

```python
from catalog import save_data, list_runs, catalog_path, is_first_run

# 保存数据
fpath = save_data("kw-discover", data_dict, metadata={"seed": "coffee maker"})

# 查询历史
runs = list_runs("kw-analyze", limit=10)

# 首次运行检测
if is_first_run():
    print("Welcome! Setting up data persistence...")
```

## 查询历史数据

```bash
# 列出所有历史记录
python3 scripts/catalog.py list

# 按类型过滤
python3 scripts/catalog.py list kw-analyze

# 读取具体数据文件
cat ~/Documents/amazon-data/kw-discover-20260514_103000.json | python3 -m json.tool

# 用 jq 提取摘要
jq '[.runs[] | {type, ts: .timestamp[0:16], meta: .metadata}]' ~/Documents/amazon-data/_catalog.json
```

## 智能体自动保存规范

| 触发场景 | 自动保存 | 数据类型 |
|---------|---------|---------|
| 关键词发现 | 优先用 `kw_discovery.py` 脚本 | `kw-discover` |
| 竞争分析 | OpenClaw 通过 cdp-bridge MCP 抓取后调用 `catalog.save_data()` 保存 | `kw-analyze` |
| 产品情报 | OpenClaw 通过 cdp-bridge MCP 抓取后调用 `catalog.save_data()` 保存 | `product-intel` |
| 排名快照 | OpenClaw 通过 cdp-bridge MCP 抓取后追加写入排名历史 | `rank-snapshot` |
| BSR 深度扫描 | OpenClaw 通过 cdp-bridge MCP 抓取后调用 `catalog.save_data()` 保存 | `bsr-scan` |

**MCP 浏览器操作不自动落盘。** 智能体在完成页面抓取后，应主动保存结构化 JSON，或明确告诉用户“本次只展示结果，未写入本地数据目录”。

## 跳过保存

所有脚本支持 `--no-save` 标志跳过数据持久化（仅输出到 stdout）。
