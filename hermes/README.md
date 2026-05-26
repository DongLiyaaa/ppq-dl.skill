## Hermes Adapter

This subtree adds a Hermes-compatible `ppq-dl` skill without changing the root OpenClaw skill.

OpenClaw remains the source of truth at the repo root:

- `/Users/dongli/codex/ppq-dl/SKILL.md`
- `/Users/dongli/codex/ppq-dl/setup.sh`

Hermes gets its own installable skill bundle here:

- `/Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl`

### Preferred install into Hermes

From this repo:

```bash
bash /Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl/scripts/install_hermes.sh
```

If you want the installer to also launch a local debug browser and auto-write
`browser.cdp_url` when possible:

```bash
bash /Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl/scripts/install_hermes.sh --launch-browser
```

The installer will:

- symlink the skill into `~/.hermes/skills/ecommerce/ppq-dl`
- merge `browser` and `terminal` into Hermes `toolsets`
- run the skill's `setup.sh`
- auto-write `browser.cdp_url` when a local CDP websocket is detectable

Then start Hermes in the terminal and attach a real Chrome/Brave/Chromium session if `browser.cdp_url` was not auto-filled:

```text
/browser connect
```

The lower-level symlink-only installer remains available:

```bash
bash /Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl/scripts/install_local.sh
```

Detailed Hermes usage is in:

- `/Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl/SKILL.md`
- `/Users/dongli/codex/ppq-dl/hermes/ecommerce/ppq-dl/references/browser-cdp-setup.md`
