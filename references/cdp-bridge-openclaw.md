# cdp-bridge 与 OpenClaw 接入说明

## 配置 MCP

在本地 OpenClaw 中写入 cdp-bridge MCP：

```bash
openclaw mcp set cdp-bridge '{"command":"uvx","args":["cdp-bridge@latest"]}'
```

如果使用常驻 HTTP 模式：

```bash
uvx cdp-bridge@latest --transport streamable-http --port 8000
openclaw mcp set cdp-bridge '{"type":"streamableHttp","url":"http://127.0.0.1:8000/mcp"}'
```

默认本地模式推荐 stdio，因为它最贴合单机 OpenClaw 使用。

## 浏览器扩展

cdp-bridge 需要浏览器扩展连接本地 WebSocket 服务，默认端口为 `18765`。

加载方式：

1. 打开 `chrome://extensions/`。
2. 开启开发者模式。
3. 选择“加载已解压的扩展程序”。
4. 选择仓库里的 `src/cdp_bridge/tmwd_cdp_bridge` 目录。

运行 `bash setup.sh` 会把该仓库拉到 `.vendor/cdp-bridge-mcp/`，并输出准确扩展路径。

## 可用工具

OpenClaw 连接成功后，应能看到下列工具：

| 工具 | 用途 |
|---|---|
| `browser_get_tabs` | 获取已连接标签页 |
| `browser_scan` | 扫描当前页面内容 |
| `browser_execute_js` | 执行页面 JavaScript |
| `browser_switch_tab` | 切换 MCP 活动标签页 |
| `browser_batch` | 批量执行浏览器命令 |
| `browser_wait` | 等待 JS 条件满足 |
| `browser_navigate` | 跳转当前标签页 |
| `browser_screenshot` | 获取页面截图 |

## 诊断

如果 OpenClaw 看不到工具：

1. 运行 `openclaw mcp show cdp-bridge` 确认配置存在。
2. 运行 `uvx cdp-bridge@latest --help` 确认命令可启动。
3. 重启 OpenClaw gateway 或新开会话。
4. 确认 Chrome 扩展已加载，扩展里端口为 `18765`。

如果工具存在但页面为空：

1. 先调用 `browser_get_tabs`。
2. 如果没有标签页，手动在 Chrome 打开 Amazon 页面。
3. 检查是否有验证码、未登录、地区拦截或页面未加载。

