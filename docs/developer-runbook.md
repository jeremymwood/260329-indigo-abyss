# Developer Runbook

## Daily workflow

1. Sync latest main:
   - `git checkout main`
   - `git pull --ff-only`
2. Create issue branch:
   - `git checkout -b issue-<number>-<short-name>`
3. Run app locally:
   - `bin/rails db:prepare`
   - `bin/rails server`
4. Validate before push:
   - `ruby bin/prepush`
5. Push branch and open PR:
   - `git push -u origin <branch-name>`

## Common commands

- Tests: `bin/rails test`
- Lint: `bin/rubocop`
- Security scan: `bin/brakeman --no-pager`
- CI workflow status: `gh run list --limit 10`

## Windows troubleshooting

### `bin/rails server` fails to boot

- Ensure Ruby from `ruby -v` matches `.ruby-version`.
- Run `bundle install` to restore missing gems.
- Run `bin/rails db:prepare` to recreate missing local DB/schema state.

### Push takes longer than expected

- This repo runs `ruby bin/prepush` on push.
- Wait for local `rubocop` and `rails test` to finish before expecting remote push output.

### GitHub auth prompts keep appearing

- Verify login: `gh auth status`
- Re-authenticate if needed: `gh auth login`

### CI fails but local checks pass

- Rebase/sync with latest `main` and rerun `ruby bin/prepush`.
- Review failed logs for environment-specific issues:
  - `gh run view <run-id> --log-failed`

### Line ending warnings (LF/CRLF)

- Warnings are expected on Windows in some files.
- Avoid mass line-ending rewrites unless intentionally normalizing the repo.
