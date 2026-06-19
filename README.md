# ppq-dl

`ppq-dl` 是一个亚马逊卖家数据采集与分析 skill，当前同时提供：

- OpenClaw 版
- Hermes 版
- Codex 版
- Claude Code 版

它通过真实浏览器会话读取 Amazon 页面上的可见数据，适合做商品调研、关键词自然位/广告位分析、BSR 扫描、店铺监控和排名快照。

## 主要用途

- 抓取亚马逊商品信息：标题、ASIN、价格、评分、评论数、库存、BSR、主图、A+ 状态、视频线索和关联推荐商品。
- 分析关键词自然位：识别目标 ASIN 的自然排名位置、Top 商品分布、价格带、评论断层和品牌集中度。
- 识别搜索广告位：判断搜索结果中的 Sponsored 广告卡片、广告密度，以及目标 ASIN 是否出现在广告位或自然位。
- 记录关键词排名快照：按关键词批量跟踪目标 ASIN 排名，用于对比推广前后自然位变化。
- 做 BSR 与类目穿透：扫描 Best Sellers、Movers & Shakers、New Releases、Most Wished For 等榜单，并通过子类目发现 Top 100 以外的机会。
- 做店铺监控：从品牌店铺页提取唯一 ASIN，建立快照，对比新增、下架和产品池变化。

## 如何使用

### OpenClaw

适合已经在用 OpenClaw 的场景。

首次使用：

```bash
bash setup.sh
```

然后按提示完成两件事：

1. 配置 `cdp-bridge`
2. 在 Chrome 的 `chrome://extensions/` 中加载扩展

如果后面出现断链，优先执行：

```bash
bash scripts/cdp_bridge_doctor.sh
```

更详细的 OpenClaw 说明以 [SKILL.md](/Users/dongli/codex/ppq-dl/SKILL.md) 为准。

### Hermes

适合已经在用 Hermes 的场景。

从仓库根目录执行：

```bash
bash hermes/ecommerce/ppq-dl/scripts/install_hermes.sh
```

如果你希望安装时顺手拉起本地调试浏览器：

```bash
bash hermes/ecommerce/ppq-dl/scripts/install_hermes.sh --launch-browser
```

安装完成后：

1. 进入 Hermes CLI
2. 如有需要执行 `/browser connect`
3. 开始使用 `ppq-dl`

Hermes 版入口在：

- [hermes/README.md](/Users/dongli/codex/ppq-dl/hermes/README.md)
- [hermes/ecommerce/ppq-dl/SKILL.md](/Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl/SKILL.md)

## 数据边界

`ppq-dl` 只基于浏览器可见页面、Amazon Suggest API 和公开页面信息做判断。它不会还原真实销量、完整广告预算或 Amazon 后台不可见数据。遇到未登录、验证码、地区限制、页面改版或加载失败时，应停止并说明阻塞原因。

## 入口文件

- OpenClaw：`SKILL.md`
- Hermes：`hermes/ecommerce/ppq-dl/SKILL.md`

详细工作流、页面提取规则、输出格式和持久化规范，请以对应平台的 `SKILL.md` 为准。
