# Agent instructions — news-pipeline

Read before implementing any task:

1. **`context/agent-guidelines.md`** — how to work on this repo
2. **`context/git-workflow.md`** — branch + PR workflow (required)
3. **`context/code-review.md`** — review process before merge
4. **`context/architecture.md`** — pipeline overview
5. **`docs/`** — step-by-step course (follow phase order)
6. **`PROGRESS.md`** — mark tasks when checkpoints pass

## Default behavior

- **Always use a branch** — never commit implementation work directly to `master`
- **Open a PR** for every code change; fill `.github/pull_request_template.md`
- **Wait for review** (David / repo owner) before merge
- Small, focused changes; match existing patterns in `docs/`
- Never commit `.env`, secrets, or `logs/`
- Verify with Checkpoint commands from the relevant `docs/*.md` file
- Prefer editing `producer/`, `consumer/`, `dags/` over rewriting course docs unless asked

## Git quick reference

```bash
git checkout master && git pull origin master
git checkout -b feature/phase-1-docker-compose
# ... implement, commit ...
git push -u origin HEAD
gh pr create
```

## Stack

NewsAPI → Airflow → Kafka → Python consumer → Elasticsearch → Kibana (all via Docker Compose).
