require "test_helper"

class GithubRepositoryTest < ActiveSupport::TestCase
  # Answers requests from a script of [status, body] and remembers what was asked.
  class FakeTransport
    attr_reader :calls

    def initialize(*responses)
      @responses = responses
      @calls = []
    end

    def call(method, path, body)
      @calls << [ method, path, body ]
      @responses.shift || [ 200, {} ]
    end
  end

  def repository(transport) = GithubRepository.new(repo: "me/repo", branch: "db-backups", token: "t", transport: transport)

  test "an existing branch is left alone" do
    transport = FakeTransport.new([ 200, {} ])
    repository(transport).ensure_branch

    assert_equal 1, transport.calls.size
  end

  test "a missing branch is created as an empty branch with no parent" do
    transport = FakeTransport.new([ 404, {} ], [ 201, { "sha" => "blob" } ], [ 201, { "sha" => "tree" } ], [ 201, { "sha" => "commit" } ], [ 201, {} ])
    repository(transport).ensure_branch

    commit = transport.calls.find { |_, path, _| path.end_with?("/git/commits") }.last
    ref = transport.calls.last.last

    assert_equal [], commit[:parents]
    assert_equal "tree", commit[:tree]
    assert_equal({ ref: "refs/heads/db-backups", sha: "commit" }, ref)
  end

  test "writing a new file sends its content and no sha" do
    transport = FakeTransport.new([ 404, {} ], [ 201, {} ])
    repository(transport).put_file("backups/a.sqlite3", "data", "msg")
    body = transport.calls.last.last

    assert_equal Base64.strict_encode64("data"), body[:content]
    assert_equal "db-backups", body[:branch]
    assert_not body.key?(:sha)
  end

  test "overwriting a file sends the sha of the existing one" do
    transport = FakeTransport.new([ 200, { "sha" => "abc" } ], [ 200, {} ])
    repository(transport).put_file("backups/a.sqlite3", "data", "msg")

    assert_equal "abc", transport.calls.last.last[:sha]
  end

  test "listing a folder that doesn't exist is empty" do
    assert_equal [], repository(FakeTransport.new([ 404, {} ])).list("backups")
  end

  test "an API error raises with the status and message" do
    error = assert_raises(GithubRepository::Error) { repository(FakeTransport.new([ 401, { "message" => "Bad credentials" } ])).list("backups") }

    assert_match(/401.*Bad credentials/, error.message)
  end
end
