## Hermes 版说明

这个目录提供 `ppq-dl` 的 Hermes 适配版，不影响仓库根目录的 OpenClaw 版。

Hermes 版 skill 目录：

- `/Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl`

## 快速开始

在仓库根目录运行：

```bash
bash hermes/ecommerce/ppq-dl/scripts/install_hermes.sh
```

如果你希望安装时顺手启动本地调试浏览器：

```bash
bash hermes/ecommerce/ppq-dl/scripts/install_hermes.sh --launch-browser
```

安装完成后：

1. 打开 Hermes CLI
2. 如有需要执行 `/browser connect`
3. 开始使用 `ppq-dl`

## 说明

- 这个安装脚本会自动把 skill 放进 `~/.hermes/skills/ecommerce/ppq-dl`
- 会补齐 Hermes 所需的基本 toolsets
- 如果本地已经有可用浏览器调试端口，会自动尝试写入 `browser.cdp_url`

## 低阶命令

如果只想单独挂载 skill，不做自动配置：

```bash
bash hermes/ecommerce/ppq-dl/scripts/install_local.sh
```

更详细的说明见：

- [Hermes SKILL.md](/Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl/SKILL.md)
- [browser-cdp-setup.md](/Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl/references/browser-cdp-setup.md)
