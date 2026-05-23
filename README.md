# ppq-dl

`ppq-dl` 是一个面向 OpenClaw 的亚马逊卖家数据采集与分析 skill，通过 `cdp-bridge` MCP 接入真实 Chrome/Chromium 浏览器会话，读取 Amazon 页面上的实时可见数据。

## 主要用途

- 抓取亚马逊商品信息：标题、ASIN、价格、评分、评论数、库存、BSR、主图、A+ 状态、视频线索和关联推荐商品。
- 分析关键词自然位：识别目标 ASIN 的自然排名位置、Top 商品分布、价格带、评论断层和品牌集中度。
- 识别搜索广告位：判断搜索结果中的 Sponsored 广告卡片、广告密度，以及目标 ASIN 是否出现在广告位或自然位。
- 记录关键词排名快照：按关键词批量跟踪目标 ASIN 排名，用于对比推广前后自然位变化。
- 做 BSR 与类目穿透：扫描 Best Sellers、Movers & Shakers、New Releases、Most Wished For 等榜单，并通过子类目发现 Top 100 以外的机会。
- 做店铺监控：从品牌店铺页提取唯一 ASIN，建立快照，对比新增、下架和产品池变化。

BSR 榜单抓取注意：
- Amazon 类目榜单虽然通常显示为每页 50 个，但当前页面常常只首屏渲染 30 个；抓取前需要先核对期望数量，再滚动补齐，不能直接把首屏结果当全量。
- 当前仓库已内置固定脚本：`scripts/bsr_reset.js`、`scripts/bsr_collect.js`、`scripts/bsr_export.js`、`scripts/bsr_runtime.py`，用于 BSR 页累计抓取和最终导出，避免临场手写提示词或 DOM 选择器。

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

`setup.sh` 会优先复用系统已有的 `uvx`。如果缺失，它会先尝试 `uv` 官方安装脚本；只有官方路径失败时，才把 Homebrew 当成可选兜底，而不是前提依赖。
默认会把 OpenClaw 配置成 `stdio` 模式；如果你在使用中频繁遇到 `cdp-bridge` 断链，可以切到更稳的常驻模式：

```bash
CDP_BRIDGE_TRANSPORT=streamable-http bash setup.sh
bash scripts/run_cdp_bridge_http.sh
```

脚本会配置 OpenClaw MCP：

```bash
openclaw mcp set cdp-bridge '{"command":"uvx","args":["cdp-bridge@latest"]}'
```

然后按提示在 Chrome 的 `chrome://extensions/` 中加载 `cdp-bridge` 扩展。

## 断链恢复

如果 OpenClaw 已经看到了 `browser_*` 工具，但执行时提示桥断开，不要先重装：

1. 先等 5 到 10 秒，再重试一次 `browser_get_tabs`。`cdp-bridge` 扩展有自动重连机制。
2. 运行：

```bash
bash scripts/cdp_bridge_doctor.sh
```

3. 如果当前是 `stdio` 模式且仍频繁断链，切到 `streamable-http` 常驻模式。
4. 如果当前已经是 `streamable-http` 模式，先执行：

```bash
bash scripts/run_cdp_bridge_http.sh
```

再回到 OpenClaw 重试。

## 数据边界

`ppq-dl` 只基于浏览器可见页面、Amazon Suggest API 和公开页面信息做判断。它不会还原真实销量、完整广告预算或 Amazon 后台不可见数据。遇到未登录、验证码、地区限制、页面改版或加载失败时，应停止并说明阻塞原因。

## Skill 入口

OpenClaw 的正式 skill 入口是：

```text
SKILL.md
```

详细工作流、页面提取规则、输出格式和持久化规范请以 `SKILL.md` 为准。
