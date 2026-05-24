# Agent instructions — news-pipeline

Read before implementing any task:

1. **`context/agent-guidelines.md`** — how to work on this repo
2. **`context/git-workflow.md`** — trunk-based Git rules
3. **`context/architecture.md`** — pipeline overview
4. **`docs/`** — step-by-step course (follow phase order)
5. **`PROGRESS.md`** — mark tasks when checkpoints pass

## Default behavior

- Small, focused changes; match existing patterns in `docs/`
- Never commit `.env`, secrets, or `logs/`
- Work on `master` (trunk); short-lived branches only if needed
- Verify with Checkpoint commands from the relevant `docs/*.md` file
- Prefer editing `producer/`, `consumer/`, `dags/` over rewriting course docs unless asked

## Stack

NewsAPI → Airflow → Kafka → Python consumer → Elasticsearch → Kibana (all via Docker Compose).
