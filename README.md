# KFL

A foosball tracker for the house: 1v1 and 2v2 ladders, Elo ratings, bets and debts, head-to-head
history, achievements and league records. Rails 8, SQLite, Hotwire and Tailwind. Deployed with Kamal.

## Run it

```
bin/setup
bin/rails db:seed                  # the six players
DEMO_DATA=1 bin/rails db:seed      # optional: a pile of fake games (development only)
bin/dev
```

PINs: 7742 is a member, 2477 is an admin (edit scores, delete games, toggle rating decay). They live
in `SessionsController`, so keep the repo private.

## Tests

```
PARALLEL=1 bin/rails test
bundle exec rubocop
bundle exec brakeman
```

## How ratings work

Chess-style Elo with a margin bonus; see the Formula button in the app for the live numbers. Ratings,
badges and records are rebuilt from the full game history after every change, so fixing or deleting a
game is always safe. Players who sit out for more than a week drift back toward 1000 (admins can switch
this off from the leaderboard).

## Deploying

```
bundle exec kamal deploy
```

Secrets come from `.kamal/secrets`: the Rails master key and the backup token (below).

## Backups

`DatabaseBackupJob` runs every night. It snapshots the live database, checks it, and pushes it to the
`db-backups` branch of this repo as `backups/kfl-YYYY-MM-DD.sqlite3`, keeping 30 days. Admins see
"Last backup" in the footer, in red if it's overdue.

- The token is a fine-grained GitHub token with Contents read and write on this repo, stored in
  `~/.kfl_github_token` and passed to the server as `GITHUB_BACKUP_TOKEN`. **It expires** (at most a
  year after it's made), so renew it, update the file and redeploy.
- Run one by hand: `bundle exec kamal app exec --reuse "bin/rails runner 'DatabaseBackupJob.perform_now'"`.
- Pull the newest one down: `script/pull_db` (saves it in `storage/`), or `script/pull_db --replace-dev`
  to make it your development database. The backups contain every game, so keep the repo private.
