# Agent guidelines — news-pipeline

## Goal

Help the learner build a **real-time news pipeline** by implementing code in this repo, following `docs/` in order. Teach briefly; do not skip verification steps.

## Implementation rules

1. **Follow the course** — `docs/00-overview.md` → `06-putting-it-together.md`. Do not jump phases unless the user explicitly asks.
2. **Minimal diffs** — Only change files required for the task. No drive-by refactors.
3. **Secrets** — Use `.env` locally; never commit `.env`. Commit `.env.example` only with empty values.
4. **Comments** — English comments in Python/shell; explain non-obvious lines only.
5. **Docker vs host** — From laptop: `localhost:9092`, `localhost:9200`. From containers: `kafka:29092`, `http://elasticsearch:9200`.
6. **Checkpoints** — After each task, run the Checkpoint commands from that doc and report pass/fail.
7. **PROGRESS.md** — Update checkboxes and `context/phases/current.md` when a phase task is verified.
8. **Git / PRs** — Always work on a branch (`feature/*`, `chore/*`, `fix/*`). Open a PR for every change; see `context/git-workflow.md` and `context/code-review.md`. Wait for review before merge.
9. **Finish a task → Git** — When a phase task or logical chunk is done and verified: `git status` (no `.env`), commit with a clear message, `git push -u origin <branch>`. Tell the user the branch name and that a PR is ready if not opened yet.

## Where code lives

| Path | Role |
|------|------|
| `producer/producer.py` | NewsAPI → Kafka |
| `consumer/consumer.py` | Kafka → sentiment → Elasticsearch |
| `dags/*.py` | Airflow schedules |
| `docker-compose.yml` | Infrastructure |
| `scripts/*.sh` | Health, restart, logs |

## When stuck

1. `TROUBLESHOOTING.md`
2. Relevant `docs/0x-*.md` Common errors section
3. `docker compose ps` and `docker compose logs <service>`

## Out of scope unless requested

- Cloud deploy (AWS/GCP)
- Replacing the course docs with different architecture
