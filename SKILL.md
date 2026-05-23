---
name: ppq-dl
description: ppq-dl 亚马逊卖家数据工具集，通过 cdp-bridge MCP 接入真实 Chrome/Chromium 浏览器会话，获取 Amazon 实时数据。覆盖关键词发现、搜索竞争分析、产品情报、排名快照、BSR/类目穿透、榜单扫描、店铺监控和选品判断。触发词：关键词发现、关键词扩展、排名监控、排名查询、竞品分析、BSR、产品情报、卖家数据、帮我分析、帮我查、帮我发现、帮我监控、类目穿透、子类目、BSR top100、top 100 以后、深度排名、类目排名、Movers Shakers、New Releases、店铺监控、竞对上新、选品方法论、ppq-dl 选品、亚马逊数据工具。
compatibility: OpenClaw skill；需要 jq、curl、python3、Chrome/Chromium、uv/uvx、cdp-bridge MCP 浏览器扩展。首次使用运行 `bash setup.sh`，它会配置 `cdp-bridge` MCP 并提示浏览器扩展加载路径。
---

# ppq-dl

通过 **cdp-bridge MCP** 接入用户真实浏览器会话，从 Amazon 页面读取实时卖家数据。这个 skill 面向 OpenClaw 使用：浏览器动作必须优先走 MCP 工具，而不是自行启动爬虫浏览器或调用旧的本地 HTTP 桥。

## 核心原则

- **浏览器层只用 `cdp-bridge` MCP**：优先调用 `browser_get_tabs`、`browser_switch_tab`、`browser_navigate`、`browser_wait`、`browser_execute_js`、`browser_scan`、`browser_screenshot`。
- **复用用户真实登录态**：先查找已打开的 Amazon 标签页；没有再打开新页。不要要求用户导出 Cookie，不要把账号态搬到脚本里。
- **先检查再执行**：每次任务先确认 `cdp-bridge` MCP 可见、Chrome 已打开、扩展已连接、目标页面可访问。
- **截图用于关键确认**：登录状态、验证码、首次探索新页面、数据异常、弹窗或选项卡切换后，都必须用 `browser_screenshot` 确认。
- **有 MCP 工具就不用旧脚本直控浏览器**：本包保留 Python 脚本只做非浏览器数据处理和持久化；需要页面交互时由 OpenClaw 调用 cdp-bridge MCP 工具完成。
- **不要伪造成功**：下载、抓取、排名、BSR、店铺监控都必须有真实页面数据或明确说明阻塞原因。

## 环境自举

每次进入本 skill，先执行下面检查。

1. 定位技能目录：`SKILL_DIR = 当前 SKILL.md 所在目录`。
2. 检查 OpenClaw 是否暴露 `cdp-bridge` MCP 工具，至少应能看到 `browser_get_tabs` 或同族浏览器工具。
3. 如果工具不可见，运行：

```bash
bash setup.sh
```

4. `setup.sh` 会写入 OpenClaw MCP 配置：

```bash
openclaw mcp set cdp-bridge '{"command":"uvx","args":["cdp-bridge@latest"]}'
```

5. 按脚本输出的路径，在 Chrome/Chromium 的 `chrome://extensions/` 里开启开发者模式，并加载 `tmwd_cdp_bridge` 扩展目录。
6. 重启 OpenClaw gateway 或新开会话后，再次确认 MCP 工具可用。

## cdp-bridge 工具映射

| 目标 | 首选工具 |
|---|---|
| 列出真实浏览器标签页 | `browser_get_tabs` |
| 切换当前 MCP 活动标签页 | `browser_switch_tab` |
| 打开或跳转 Amazon 页面 | `browser_navigate` |
| 等待 DOM 条件 | `browser_wait` |
| 执行页面 JavaScript | `browser_execute_js` |
| 读取页面文本/简化 HTML | `browser_scan` |
| 关键状态截图 | `browser_screenshot` |

## 标签页与登录态流程

1. 用 `browser_get_tabs` 查找 `amazon.com`、`www.amazon.com` 或目标站点域名的已有标签页。
2. 找到后用 `browser_switch_tab` 绑定到该标签页。
3. 找不到时，用 `browser_navigate` 打开目标 Amazon 页面。
4. 用 `browser_screenshot` 或 `browser_scan` 判断页面顶部是已登录、未登录、验证码还是地区/机器人拦截。
5. 未登录或验证码时立即停止，要求用户在真实浏览器手动完成登录/验证后再继续。

禁止行为：

- 不要用 `about:blank` 作为健康检查。
- 不要跳过登录/验证码检查。
- 不要直接写本地 HTTP bridge curl。
- 不要用 Playwright 新开无登录态浏览器替代用户真实浏览器，除非用户明确要求。

## 操作规范一：关键词发现

数据源：Amazon Suggest API。无需浏览器。

优先用脚本：

```bash
python3 scripts/kw_discovery.py "coffee maker" 3
```

输出要求：

- 列出建议词总数和关键词清单。
- 标注来源为 Amazon Suggest API。
- 如保存成功，给出 `~/Documents/amazon-data/` 下的文件路径。

## 操作规范二：搜索竞争分析

数据源：cdp-bridge MCP → Amazon 搜索结果页。

流程：

1. 复用或打开搜索页：`https://www.amazon.com/s?k={URL编码关键词}`。
2. 等待搜索结果卡片出现：`[data-component-type="s-search-result"]`。
3. 用 `browser_execute_js` 提取搜索结果卡片。
4. 需要用户可见确认时，先截图再分析。

搜索结果提取 JS：

```javascript
JSON.stringify(Array.from(document.querySelectorAll('[data-component-type="s-search-result"]')).slice(0, 24).map(function (card, i) {
  var asin = card.getAttribute('data-asin') || '';
  var titleNode = card.querySelector('h2');
  var title = titleNode ? titleNode.textContent.trim() : '';
  var rating = card.querySelector('[aria-label*="stars"]');
  var review = card.querySelector('a[href*="customerReviews"] span');
  var whole = card.querySelector('.a-price-whole');
  var frac = card.querySelector('.a-price-fraction');
  var price = whole ? whole.textContent.trim().replace(/\.$/, '') : '';
  if (price && frac) price += '.' + frac.textContent.trim();
  return {
    pos: i + 1,
    asin: asin,
    title: title,
    brandGuess: title.split(/\s+/)[0] || '',
    rating: rating ? rating.getAttribute('aria-label') : '',
    reviews: review ? review.textContent.trim().replace(/[()]/g, '') : '',
    price: price || '',
    sponsored: !!card.querySelector('.puis-sponsored-label-text, [aria-label="Sponsored"]')
  };
}))
```

输出报告至少包含：

- 目标关键词、站点、抓取时间。
- Top 24 ASIN、标题、价格、评分、评论数、广告标记。
- 目标 ASIN 的自然/广告位置，如未出现则说明当前页未命中。
- 竞争强度判断：头部评论量、广告密度、价格带、品牌集中度。

## 操作规范三：产品情报

数据源：cdp-bridge MCP → Amazon 产品详情页。

流程：

1. 打开 `https://www.amazon.com/dp/{ASIN}`。
2. 等待 `#productTitle` 或页面主体加载。
3. 分段滚动触发 A+、轮播和关联模块加载。
4. 用 `browser_execute_js` 提取基础信息、图片、A+ 和关联产品。

基础信息提取 JS：

```javascript
(function () {
  var text = document.body.textContent || '';
  var bsrStart = text.indexOf('Best Sellers Rank');
  var bsr = bsrStart >= 0 ? text.slice(bsrStart, bsrStart + 350).replace(/\s+/g, ' ') : '';
  return JSON.stringify({
    title: document.querySelector('#productTitle')?.textContent?.trim() || '',
    price: document.querySelector('.a-price .a-offscreen')?.textContent?.trim() || '',
    listPrice: document.querySelector('.basisPrice .a-offscreen')?.textContent?.trim() || '',
    rating: document.querySelector('#acrPopover')?.getAttribute('title') || '',
    reviewCount: document.querySelector('#acrCustomerReviewText')?.textContent?.trim() || '',
    stock: document.querySelector('#availability span')?.textContent?.trim() || '',
    bsr: bsr,
    mainImage: document.querySelector('#landingImage')?.getAttribute('src') || '',
    hasAPlus: !!document.querySelector('#aplus_feature_div')
  });
})()
```

输出报告至少包含：

- 标题、价格、评分、评论数、库存状态、BSR。
- 主图/A+是否存在。
- Listing 卖点和页面承接风险。
- 数据不可见时说明是页面缺失、未加载、地区差异还是被拦截。

## 操作规范四：排名快照

数据源：cdp-bridge MCP → Amazon 搜索页。

流程：

1. 对每个关键词打开搜索页。
2. 提取第一页搜索卡片并匹配目标 ASIN。
3. 未命中时只允许有限检查第 2 页；不要长时间翻页造成风控。
4. 结果保存到 `~/Documents/keyword-rankings/ranking_history.json`，可用 `scripts/catalog.py` 注册摘要。

排名提取 JS：

```javascript
(function (targetAsin) {
  var cards = Array.from(document.querySelectorAll('[data-component-type="s-search-result"]'));
  var pos = -1;
  cards.forEach(function (card, i) {
    if ((card.getAttribute('data-asin') || '') === targetAsin) pos = i + 1;
  });
  return JSON.stringify({ position: pos, totalCards: cards.length, url: location.href });
})('{ASIN}')
```

输出要求：

- 表格列：关键词、页码、位置、是否广告位、Top ASIN、抓取时间。
- 所有关键词都无数据时不要写入历史，先截图确认页面状态。

## 操作规范五：BSR 与类目穿透

数据源：cdp-bridge MCP → Amazon Best Sellers / Movers & Shakers / New Releases / Most Wished For。

原则：

- 优先遍历子类目榜单，不要暴力翻搜索页。
- 每个榜单页面预计最多 50 个左右可见商品，滚动不足会漏数据。
- 页面异常时截图确认，不要把空结果当作类目无产品。

BSR 页面产品提取 JS：

```javascript
JSON.stringify(Array.from(document.querySelectorAll('.p13n-sc-uncoverable-faceout')).map(function (card, i) {
  var asin = card.id || '';
  var title = card.querySelector('[class*=line-clamp]')?.textContent?.trim() || '';
  var rating = card.querySelector('a[aria-label*="stars"]')?.getAttribute('aria-label') || '';
  var text = card.textContent.replace(/\s+/g, ' ');
  var price = (text.match(/\$\s?\d+(?:\.\d{2})?/) || [''])[0];
  return { rank: i + 1, asin: asin, title: title, rating: rating, price: price };
}).filter(function (x) { return x.asin || x.title; }))
```

输出要求：

- 按子类目/榜单来源去重 ASIN。
- 标注父类目独有、子类目独有、重复 ASIN。
- 给出机会判断：价格带断层、评论断层、品牌集中、低评高排、新品上升。

## 操作规范六：店铺监控

数据源：cdp-bridge MCP → Amazon 品牌店铺页。

流程：

1. 从产品页寻找 `a[href*="/stores/"]`，或使用用户提供的店铺 URL。
2. 打开店铺页，分段滚动直到 ASIN 数稳定。
3. 用链接正则提取唯一 ASIN，不依赖 `[data-asin]`。
4. 保存快照并与上次快照比对：新增、下架、无变化。
5. 对新增 ASIN 再跑产品情报。

店铺 ASIN 提取 JS：

```javascript
JSON.stringify(Array.from(document.querySelectorAll('a[href*="/dp/"]')).map(function (a) {
  return ((a.getAttribute('href') || '').match(/\/dp\/([A-Z0-9]{10})/) || [])[1] || '';
}).filter(Boolean).filter(function (asin, idx, arr) {
  return arr.indexOf(asin) === idx;
}))
```

## 数据持久化

持久化规范见 `references/data-persistence.md`。

默认目录：

- 结构化数据：`~/Documents/amazon-data/`
- 排名历史：`~/Documents/keyword-rankings/`
- 全局索引：`~/Documents/amazon-data/_catalog.json`

保存数据时必须包含：

- `type`
- `timestamp`
- `metadata`
- `data`
- 数据来源和页面 URL

## 输出风格

- 用正式、简洁、可执行的中文输出。
- 每份报告必须标注数据来源、抓取时间、可见数据范围和置信度。
- 数据不足时明确说明：`当前仅能基于可见页面数据判断，无法推断不可见销量或完整市场规模。`
- 不替用户做最终经营决策，只给证据、判断依据、可选动作和风险。
