# ppq-dl

`ppq-dl` 是一个面向 OpenClaw 的亚马逊卖家数据采集与分析 skill，通过 `cdp-bridge` MCP 接入真实 Chrome/Chromium 浏览器会话，读取 Amazon 页面上的实时可见数据。

## 主要用途

- 抓取亚马逊商品信息：标题、ASIN、价格、评分、评论数、库存、BSR、主图、A+ 状态、视频线索和关联推荐商品。
- 分析关键词自然位：识别目标 ASIN 的自然排名位置、Top 商品分布、价格带、评论断层和品牌集中度。
- 识别搜索广告位：判断搜索结果中的 Sponsored 广告卡片、广告密度，以及目标 ASIN 是否出现在广告位或自然位。
- 记录关键词排名快照：按关键词批量跟踪目标 ASIN 排名，用于对比推广前后自然位变化。
- 做 BSR 与类目穿透：扫描 Best Sellers、Movers & Shakers、New Releases、Most Wished For 等榜单，并通过子类目发现 Top 100 以外的机会。
- 做店铺监控：从品牌店铺页提取唯一 ASIN，建立快照，对比新增、下架和产品池变化。

## 使用前提

- OpenClaw
- Chrome 或 Chromium
- `uv` / `uvx`
- `python3`
- `jq`、`curl`
- `cdp-bridge` MCP 浏览器扩展

首次使用：

```bash
bash setup.sh
```

脚本会配置 OpenClaw MCP：

```bash
openclaw mcp set cdp-bridge '{"command":"uvx","args":["cdp-bridge@latest"]}'
```

然后按提示在 Chrome 的 `chrome://extensions/` 中加载 `cdp-bridge` 扩展。

## 数据边界

`ppq-dl` 只基于浏览器可见页面、Amazon Suggest API 和公开页面信息做判断。它不会还原真实销量、完整广告预算或 Amazon 后台不可见数据。遇到未登录、验证码、地区限制、页面改版或加载失败时，应停止并说明阻塞原因。

## Skill 入口

OpenClaw 的正式 skill 入口是：

```text
SKILL.md
```

详细工作流、页面提取规则、输出格式和持久化规范请以 `SKILL.md` 为准。
