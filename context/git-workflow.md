# Git workflow — branch + PR + code review

## Model

We use **trunk-based development** with **mandatory pull requests**. `master` is always runnable; all changes land via reviewed PRs.

```
master ──●──●──●──●──●──►  (integration branch — merge via PR only)
          \    /
           ●──●            feature/chore branch (1 task, < 2 days)
                └──► PR ──► review ──► merge
```

## Branches

| Branch | Use |
|--------|-----|
| `master` | Trunk; **never commit directly** for implementation work |
| `feature/<short-name>` | New functionality (e.g. `feature/phase-1-docker-compose`) |
| `chore/<short-name>` | Docs, workflow, tooling (e.g. `chore/git-pr-workflow`) |
| `fix/<short-name>` | Bug fixes |

Delete the branch after merge.

## Daily flow (agents and humans)

1. `git checkout master && git pull origin master`
2. `git checkout -b feature/<short-name>`
3. Implement **one** logical change (one phase task or one fix)
4. `git status` — confirm `.env` is **not** staged
5. Commit with clear messages; **push branch** (`git push -u origin HEAD`)
6. Open PR: `gh pr create` (template auto-fills from `.github/pull_request_template.md`)

**Agents:** After completing and verifying a course phase task, commit and push before moving to the next task (unless the user says otherwise).
7. Wait for review — see `context/code-review.md`
8. After merge: `git checkout master && git pull origin master`

## Commit messages

Format: `type: short description`

Types: `feat`, `fix`, `docs`, `chore`, `refactor`

Examples:

- `feat: add producer.py for NewsAPI to Kafka`
- `feat: fill docker-compose.yml for phase 1 stack`
- `docs: add Git PR workflow and code review guide`
- `fix: kafka bootstrap URL for Airflow container`

## Never commit

- `.env`, API keys, passwords
- `logs/`, `.venv/`, `__pycache__/`
- Large local data dumps

## Pull requests (required)

- **One PR = one task** (e.g. Phase 1 Task 4, or one script)
- Fill summary + test plan with **Checkpoint commands** from `docs/*.md`
- Link the doc task when applicable (e.g. `docs/01-docker.md` Task 4)
- Do **not** merge your own PR unless the user explicitly asks after approval

## Agent safety rules

- Do **not** `git push --force` to `master`
- Do **not** commit or push unless the user asks (unless opening a PR is the explicit task)
- Do **not** amend commits unless user explicitly requests
- Do **not** skip hooks (`--no-verify`)
- Run `git diff` before commit; reject if secrets appear
- **Always** work on a branch for code changes — never commit implementation directly to `master`
