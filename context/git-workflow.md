# Git workflow — trunk-based

## Model

We use **trunk-based development**: one trunk branch (`master`), small frequent commits, short-lived branches only when necessary.

```
master ──●──●──●──●──●──►  (always deployable / runnable)
          \    /
           ●──●            feature branch (optional, < 2 days)
```

## Branches

| Branch | Use |
|--------|-----|
| `master` | Default trunk; all work merges here |
| `feature/<short-name>` | Optional; delete after merge |
| **Avoid** | Long-lived `develop`, `staging`, per-dev branches |

## Daily flow

1. `git pull origin master` before starting work
2. Implement one logical change (one phase task or fix)
3. `git status` — confirm `.env` is **not** staged
4. Commit on `master` OR open a short `feature/*` branch → merge to `master` → delete branch
5. `git push origin master` when the user asks to push

## Commit messages

Format: `type: short description`

Types: `feat`, `fix`, `docs`, `chore`, `refactor`

Examples:

- `feat: add producer.py for NewsAPI to Kafka`
- `docs: complete docker-compose in phase 1`
- `fix: kafka bootstrap URL for Airflow container`

## Never commit

- `.env`, API keys, passwords
- `logs/`, `.venv/`, `__pycache__/`
- Large local data dumps

## Pull requests (optional)

For learning solo, pushing to `master` is fine. If using PRs:

- Keep PRs small (one phase or one file group)
- Description: what + how to test (Checkpoint commands)
- Merge with squash or merge commit; delete feature branch

## Agent-specific

- Do **not** `git push --force` to `master`
- Do **not** amend commits unless user explicitly requests
- Do **not** skip hooks (`--no-verify`)
- Run `git diff` before commit; reject if secrets appear
