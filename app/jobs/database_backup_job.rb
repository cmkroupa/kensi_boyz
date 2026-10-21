# Nightly: snapshot the database and push it to GitHub. Retries a few times on
# network trouble; if it still fails the footer shows the backup as stale.
class DatabaseBackupJob < ApplicationJob
  retry_on GithubRepository::Error, wait: 5.minutes, attempts: 3

  def perform
    DatabaseBackup.run
  end
end
