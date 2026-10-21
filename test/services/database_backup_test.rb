require "test_helper"

class DatabaseBackupTest < ActiveSupport::TestCase
  class FakeRepository
    attr_reader :files, :deleted, :branch_ensured

    def initialize(existing = [])
      @files = {}
      @deleted = []
      @existing = existing
    end

    def ensure_branch = @branch_ensured = true
    def put_file(path, content, message) = @files[path] = content
    def list(_path) = @existing
    def delete_file(path, sha, _message) = @deleted << [ path, sha ]
  end

  setup do
    @directory = Dir.mktmpdir
    @source = File.join(@directory, "source.sqlite3")
    database = SQLite3::Database.new(@source)
    database.execute("CREATE TABLE games (id INTEGER PRIMARY KEY, score INTEGER)")
    database.execute("INSERT INTO games (score) VALUES (8), (7)")
    database.close
    @now = Time.zone.local(2026, 3, 10, 8)
    Rails.cache.clear
  end

  teardown { FileUtils.remove_entry(@directory) }

  def backup(repository, **options) = DatabaseBackup.new(repository: repository, database_path: @source, now: @now, **options)

  test "uploads a valid copy of the database under today's date" do
    repository = FakeRepository.new
    path = backup(repository).run

    assert_equal "backups/kfl-2026-03-10.sqlite3", path
    assert repository.branch_ensured

    copy = File.join(@directory, "copy.sqlite3")
    File.binwrite(copy, repository.files.fetch(path))
    database = SQLite3::Database.new(copy, readonly: true)

    assert_equal [ [ 8 ], [ 7 ] ], database.execute("SELECT score FROM games ORDER BY id")
    database.close
  end

  test "removes backups older than the retention period and keeps recent ones" do
    existing = [
      { "name" => "kfl-2026-01-01.sqlite3", "path" => "backups/kfl-2026-01-01.sqlite3", "sha" => "old" },
      { "name" => "kfl-2026-03-05.sqlite3", "path" => "backups/kfl-2026-03-05.sqlite3", "sha" => "recent" },
      { "name" => "README.md", "path" => "backups/README.md", "sha" => "other" }
    ]
    repository = FakeRepository.new(existing)
    backup(repository).run

    assert_equal [ [ "backups/kfl-2026-01-01.sqlite3", "old" ] ], repository.deleted
  end

  # Swaps in a real cache for the block; the test environment's is a null store.
  def with_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end

  test "records the time of the last successful backup" do
    with_cache do
      assert DatabaseBackup.stale?

      backup(FakeRepository.new, now: Time.current).run

      assert_not DatabaseBackup.stale?
    end
  end

  test "a failed upload is not recorded as a success" do
    repository = FakeRepository.new
    repository.define_singleton_method(:put_file) { |*| raise GithubRepository::Error, "boom" }

    with_cache do
      assert_raises(GithubRepository::Error) { backup(repository).run }
      assert_nil DatabaseBackup.last_success
    end
  end

  test "running for real needs a token" do
    original = ENV.delete("GITHUB_BACKUP_TOKEN")

    assert_raises(DatabaseBackup::Error) { DatabaseBackup.run }
  ensure
    ENV["GITHUB_BACKUP_TOKEN"] = original if original
  end

  test "the job runs the backup" do
    called = false
    original = DatabaseBackup.method(:run)
    DatabaseBackup.define_singleton_method(:run) { called = true }

    DatabaseBackupJob.perform_now

    assert called
  ensure
    DatabaseBackup.define_singleton_method(:run, original)
  end
end
