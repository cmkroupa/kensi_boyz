require "net/http"
require "base64"
require "json"

# Just enough of GitHub's API to keep backup files on one branch of one repo:
# make the branch, write a file, list a folder, delete a file. Network problems
# and API errors both raise Error so the job can retry.
class GithubRepository
  class Error < StandardError; end

  API = "https://api.github.com".freeze

  # transport: ->(method, path, body) { [ status, parsed_body ] }, swappable in tests.
  def initialize(repo:, branch:, token:, transport: nil)
    @repo = repo
    @branch = branch
    @token = token
    @transport = transport || method(:http_request)
  end

  def ensure_branch
    return if call(:get, "/repos/#{@repo}/branches/#{@branch}", ok: [ 200, 404 ]).first == 200

    blob = call(:post, "/repos/#{@repo}/git/blobs", { content: "Database backups. Nothing else lives on this branch.\n", encoding: "utf-8" }).last
    tree = call(:post, "/repos/#{@repo}/git/trees", { tree: [ { path: "README.md", mode: "100644", type: "blob", sha: blob["sha"] } ] }).last
    commit = call(:post, "/repos/#{@repo}/git/commits", { message: "Start the backup branch", tree: tree["sha"], parents: [] }).last
    call(:post, "/repos/#{@repo}/git/refs", { ref: "refs/heads/#{@branch}", sha: commit["sha"] })
  end

  # The blob sha of a file on the branch, or nil if it isn't there.
  def file_sha(path)
    status, body = call(:get, "/repos/#{@repo}/contents/#{path}?ref=#{@branch}", ok: [ 200, 404 ])
    body["sha"] if status == 200
  end

  def put_file(path, content, message)
    body = { message: message, content: Base64.strict_encode64(content), branch: @branch }
    sha = file_sha(path)
    body[:sha] = sha if sha
    call(:put, "/repos/#{@repo}/contents/#{path}", body)
  end

  # [{ "name" => ..., "path" => ..., "sha" => ... }] for a folder, empty if it doesn't exist.
  def list(path)
    status, body = call(:get, "/repos/#{@repo}/contents/#{path}?ref=#{@branch}", ok: [ 200, 404 ])
    status == 200 ? body : []
  end

  def delete_file(path, sha, message)
    call(:delete, "/repos/#{@repo}/contents/#{path}", { message: message, sha: sha, branch: @branch })
  end

  private
    def call(method, path, body = nil, ok: [ 200, 201 ])
      status, parsed = @transport.call(method, path, body)
      raise Error, "GitHub #{method.upcase} #{path.split('?').first} returned #{status}: #{parsed.is_a?(Hash) ? parsed['message'] : parsed}" unless ok.include?(status)

      [ status, parsed ]
    end

    def http_request(method, path, body)
      uri = URI("#{API}#{path}")
      request = Net::HTTP.const_get(method.to_s.capitalize).new(uri)
      request["Authorization"] = "Bearer #{@token}"
      request["Accept"] = "application/vnd.github+json"
      request["X-GitHub-Api-Version"] = "2022-11-28"
      request["User-Agent"] = "kfl-backup"
      request.body = JSON.generate(body) if body

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 60) { |http| http.request(request) }
      [ response.code.to_i, response.body.to_s.empty? ? {} : JSON.parse(response.body) ]
    rescue SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => error
      raise Error, "#{error.class}: #{error.message}"
    end
end
