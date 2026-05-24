# Code review — news-pipeline

Every code change goes through a **pull request** and a **human review** before merge to `master`.

## Who reviews

- **David** (or the repo owner) reviews and approves PRs.
- Agents **prepare** the PR; they do **not** merge unless the user explicitly asks after approval.

## What reviewers check

| Area | Question |
|------|----------|
| Scope | Is the diff limited to one task/phase? Any drive-by changes? |
| Secrets | Is `.env` absent from the diff? No API keys or passwords? |
| Course alignment | Does it follow the active `docs/*.md` task and checkpoints? |
| Verification | Did the author run Checkpoint commands and report pass/fail? |
| Patterns | Does code match existing repo style and doc examples? |

## Agent responsibilities before requesting review

1. Branch from latest `master`: `feature/<short-name>` or `chore/<short-name>`
2. Small, focused commits with clear messages (`feat:`, `fix:`, `docs:`, `chore:`)
3. Fill out the PR template (summary + test plan with Checkpoint commands)
4. Run `git diff` and confirm no secrets
5. Push branch and open PR with `gh pr create`
6. **Stop** — wait for review; do not merge or push to `master` directly

## Reviewer actions

- Request changes if scope is too large, secrets appear, or checkpoints were not run
- Approve when the PR matches the task and verification notes are credible
- Merge via GitHub UI (squash or merge commit — either is fine for this repo)

## After merge

```bash
git checkout master
git pull origin master
git branch -d feature/<short-name>   # delete local branch
```

Remote feature branch is deleted automatically if "Delete branch" is checked on merge.
