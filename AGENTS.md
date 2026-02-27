# Agent Instructions

## Docs

- WhatsApp group agent: `docs/whatsapp_group_agent.md`
  - Use only when changing `app/agents/whatsapp_*.rb` or
    `app/models/whatsapp_*.rb`

## Tooling

- `mise install` - install devtools and dependencies
- `mise dev` - run dev server
- `mise test [-i <name>]` - run tests (excluding system tests)
- `mise test:system [-i <name>]` - run system tests
- `mise x -- ...` (run ad-hoc command with tools installed by mise)
  - `mise x -- bunx ...` (run ad-hoc command from NPM)
  - `mise x -- bundle e ...` (run ad-hoc command from Rubygems)

## Commit Attribution

- AI commits MUST include attribute, e.g.

```text
Co-Authored-By: Codex by OpenAI <codex@openai.com>
```

## Key Conventions

- Search with `rg` / `rg --files`
- Keep edits scoped; do not revert unrelated local changes
- Prefer project scripts in `bin/` and `mise run ...` when available (see
  available tasks with `mise tasks`)
- Run targeted verification before completion: `mise test` (or relevant subset)
