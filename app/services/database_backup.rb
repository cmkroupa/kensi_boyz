require "tmpdir"
require "sqlite3"

# Takes a consistent snapshot of the live database, checks it, uploads it to the
# backup branch as backups/kfl-YYYY-MM-DD.sqlite3 and clears out old ones.
class DatabaseBackup
  DIRECTORY = "backups".freeze
  KEEP_DAYS = 30
  STALE_AFTER = 36.hours
  LAST_SUCCESS_KEY = "database_backup:last_success".freeze

  class Error < StandardError; end

  # The real thing, configured from the environment.
  def self.run
    token = ENV["GITHUB_BACKUP_TOKEN"].presence or raise Error, "GITHUB_BACKUP_TOKEN is not set"
    repository = GithubRepository.new(repo: ENV.fetch("BACKUP_REPO", "cmkroupa/kensi_boyz"),
      branch: ENV.fetch("BACKUP_BRANCH", "db-backups"), token: token)
    new(repository: repository).run
  end

  def self.configured? = ENV["GITHUB_BACKUP_TOKEN"].present?
  def self.last_success = Rails.cache.read(LAST_SUCCESS_KEY)

  def self.stale?
    last = last_success
    last.nil? || last < STALE_AFTER.ago
  end

  def initialize(repository:, database_path: nil, keep_days: KEEP_DAYS, now: Time.current)
    @repository = repository
    @database_path = database_path || Rails.root.join(ApplicationRecord.connection_db_config.database).to_s
    @keep_days = keep_days
    @now = now
  end

  def run
    Dir.mktmpdir("kfl-backup") do |directory|
      snapshot = File.join(directory, "snapshot.sqlite3")
      take_snapshot(snapshot)
      verify(snapshot)
      @repository.ensure_branch
      @repository.put_file(remote_path, File.binread(snapshot), "Database backup #{@now.to_date}")
    end

    prune
    Rails.cache.write(LAST_SUCCESS_KEY, @now)
    remote_path
  end

  private
    def remote_path = "#{DIRECTORY}/kfl-#{@now.to_date}.sqlite3"

    # VACUUM INTO writes a clean copy even while the app is using the database.
    def take_snapshot(path)
      database = SQLite3::Database.new(@database_path, readonly: true)
      database.execute("VACUUM INTO '#{path.gsub("'", "''")}'")
    ensure
      database&.close
    end

    def verify(path)
      database = SQLite3::Database.new(path, readonly: true)
      result = database.execute("PRAGMA integrity_check").flatten.first
      raise Error, "Snapshot failed its integrity check: #{result}" unless result == "ok"
    ensure
      database&.close
    end

    def prune
      cutoff = @now.to_date - @keep_days
      @repository.list(DIRECTORY).each do |file|
        date = file["name"][/\Akfl-(\d{4}-\d{2}-\d{2})\.sqlite3\z/, 1]&.to_date
        @repository.delete_file(file["path"], file["sha"], "Remove old backup") if date && date < cutoff
      end
    end
end
