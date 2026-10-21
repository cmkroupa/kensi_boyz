require "digest"

# Ratings and records are stored results of the formula, so they go stale the moment
# its code changes. This fingerprints that code, and the app rebuilds everything on
# the first boot after the fingerprint moves, so what's on screen is always the
# current formula's numbers and nobody has to remember to recalculate.
module FormulaVersion
  FILES = %w[
    app/services/elo.rb
    app/services/rating_replay.rb
    app/services/record_replay.rb
    app/models/game.rb
  ].freeze
  KEY = "formula_version".freeze

  def self.current
    Digest::SHA256.hexdigest(FILES.map { |file| Rails.root.join(file).read }.join)[0, 8]
  end

  def self.applied = Setting.fetch(KEY)
  def self.stale? = applied != current
  def self.mark_applied = Setting.store(KEY, current)

  def self.refresh_if_stale
    Game.rebuild_derived_data if stale?
  end
end
