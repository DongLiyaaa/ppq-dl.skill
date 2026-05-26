---
name: ppq-dl
description: Use when collecting Amazon product details, keyword rankings, sponsored positions, BSR lists, or store ASIN snapshots from a real browser session in Hermes.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [amazon, ecommerce, asin, bsr, sponsored, ranking, browser, seller]
    category: ecommerce
---

# ppq-dl

Hermes 版 `ppq-dl` 用于在真实浏览器会话里读取 Amazon 页面数据，服务于商品调研、关键词自然位/广告位分析、BSR 扫描、店铺监控和排名快照。

这个目录是 Hermes 适配层，不替换仓库根目录的 OpenClaw 版。

## 适用边界

- 只基于浏览器可见页面、Amazon Suggest API 和公开页面信息做判断。
- 不承诺还原真实销量、完整广告预算或 Amazon 后台不可见数据。
- 遇到未登录、验证码、地区限制、页面改版或加载失败时，必须停止并说明阻塞原因。

## 安装与前置

首次使用，优先执行：

```bash
bash "${HERMES_SKILL_DIR}/scripts/install_hermes.sh"
```

如果当前还没有 `HERMES_SKILL_DIR`，也可以从仓库运行：

```bash
bash /absolute/path/to/ppq-dl/hermes/ecommerce/ppq-dl/scripts/install_hermes.sh
```

如果你希望它顺手启动本地调试浏览器：

```bash
bash /absolute/path/to/ppq-dl/hermes/ecommerce/ppq-dl/scripts/install_hermes.sh --launch-browser
```

完成后：

1. 进入 Hermes CLI
2. 如有需要执行 `/browser connect`
3. 开始使用 `ppq-dl`

如果还没有带调试端口的本地浏览器，可先启动：

```bash
bash "${HERMES_SKILL_DIR}/scripts/launch_local_chrome.sh"
```

健康检查：

```bash
bash "${HERMES_SKILL_DIR}/scripts/hermes_browser_doctor.sh"
```

更细的浏览器接入说明见 `references/browser-cdp-setup.md`。

## 使用原则

- 优先复用真实浏览器登录态。
- 关键页面先确认状态，再提取数据。
- 页面异常时先截图或观察，再下结论。
- 结构化数据继续使用本 skill 自带脚本保存。

## 浏览器工具

Hermes 版优先使用这些工具：

- `browser_navigate`
- `browser_snapshot`
- `browser_scroll`
- `browser_console(expression=...)`
- `browser_vision`

只有在确实需要原生 CDP 能力时，才使用 `browser_cdp`。

## 登录态与页面进入

1. 涉及用户真实浏览器登录态时，优先 `/browser connect`。
2. 如果没有连接真实浏览器，至少先确认当前 Hermes 浏览器里页面可正常访问。
3. 打开 Amazon 页面后，先用 `browser_snapshot(full=true)` 或 `browser_vision` 判断：
   - 已登录
   - 未登录
   - 验证码
   - 地区/机器人拦截
4. 未登录或验证码时立即停止，让用户先在真实浏览器完成操作。

## 操作规范一：关键词发现

数据源：Amazon Suggest API。无需浏览器。

```bash
python3 "${HERMES_SKILL_DIR}/scripts/kw_discovery.py" "coffee maker" 3
```

输出要求：

- 列出建议词总数和关键词清单。
- 标注来源为 Amazon Suggest API。
- 如保存成功，给出 `~/Documents/amazon-data/` 下的文件路径。

## 操作规范二：搜索竞争分析

数据源：Hermes 浏览器 → Amazon 搜索结果页。

流程：

1. 打开搜索页：`https://www.amazon.com/s?k={URL编码关键词}`。
2. 先用 `browser_snapshot` 确认搜索结果卡片已经出现。
3. 用 `browser_console(expression=...)` 提取结果卡片。
4. 需要视觉确认时，先 `browser_vision` 再分析。

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

数据源：Hermes 浏览器 → Amazon 产品详情页。

流程：

1. 打开 `https://www.amazon.com/dp/{ASIN}`。
2. 用 `browser_snapshot(full=true)` 或 `browser_console(expression=...)` 确认 `#productTitle` 已可读。
3. 分段滚动触发 A+、轮播和关联模块加载。
4. 用 `browser_console(expression=...)` 提取基础信息、图片、A+ 和关联产品。

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

数据源：Hermes 浏览器 → Amazon 搜索页。

流程：

1. 对每个关键词打开搜索页。
2. 提取第一页搜索卡片并匹配目标 ASIN。
3. 未命中时只允许有限检查第 2 页；不要长时间翻页造成风控。
4. 结果保存到 `~/Documents/keyword-rankings/ranking_history.json`，必要时用 `scripts/catalog.py` 注册摘要。

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

数据源：Hermes 浏览器 → Amazon Best Sellers / Movers & Shakers / New Releases / Most Wished For。

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

数据源：Hermes 浏览器 → Amazon 品牌店铺页。

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

本 skill 自带的持久化脚本：

- `${HERMES_SKILL_DIR}/scripts/catalog.py`
- `${HERMES_SKILL_DIR}/scripts/config.py`
- `${HERMES_SKILL_DIR}/scripts/kw_discovery.py`

## 输出风格

- 用正式、简洁、可执行的中文输出。
- 每份报告必须标注数据来源、抓取时间、可见数据范围和置信度。
- 数据不足时明确说明：`当前仅能基于可见页面数据判断，无法推断不可见销量或完整市场规模。`
- 不替用户做最终经营决策，只给证据、判断依据、可选动作和风险。
