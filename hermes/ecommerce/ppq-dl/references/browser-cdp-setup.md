# Hermes 浏览器接入

`ppq-dl` 在 Hermes 下优先走两种方式：

1. **CLI 里直接 `/browser connect`**
2. **配置 `browser.cdp_url` 持久连接本地 Chrome/Brave/Chromium**

## 最低可用方式

先确保 Hermes 开了浏览器工具集：

```bash
hermes config set toolsets '["hermes-cli", "browser", "terminal"]'
```

然后在 Hermes CLI 会话里执行：

```text
/browser connect
```

这会优先连接本地 `127.0.0.1:9222` 的 Chromium 调试端口；如果端口未起来，Hermes 会尝试自动拉起本地浏览器。

## 手动启动本地调试浏览器

如果你想先把本地 Chrome/Brave/Chromium 准备好，再让 Hermes 接入，可运行：

```bash
bash "${HERMES_SKILL_DIR}/scripts/launch_local_chrome.sh"
```

这个脚本会用独立调试 profile 启动浏览器：

- `--remote-debugging-port=9222`
- `--user-data-dir=$HOME/.hermes/chrome-debug`
- `--no-first-run`
- `--no-default-browser-check`

## 持久化 `browser.cdp_url`

如果你希望 Hermes 每次启动都自动连本地浏览器：

1. 先启动本地调试浏览器
2. 访问：

```bash
curl -s http://127.0.0.1:9222/json/version
```

3. 取出 `webSocketDebuggerUrl`
4. 写入 Hermes 配置：

```bash
hermes config set browser.cdp_url ws://127.0.0.1:9222/devtools/browser/<id>
```

## 诊断

```bash
bash "${HERMES_SKILL_DIR}/scripts/hermes_browser_doctor.sh"
```

它会检查：

- `hermes` 是否在 PATH
- `browser` / `terminal` 工具集是否大概率已开启
- `127.0.0.1:9222/json/version` 是否可达
- 当前本地调试端口有没有返回 `webSocketDebuggerUrl`
