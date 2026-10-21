class Player < ApplicationRecord
  include Stats
  include Records

  has_many :participations, dependent: :destroy
  has_many :games, through: :participations
  has_many :achievements, dependent: :destroy
  has_many :record_breaks, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :alphabetically, -> { order(:name) }

  # Ranked players first, best rating on top; players with no games sit at the bottom.
  scope :ranked_in, ->(mode) {
    order(arel_table[:"#{mode}_games_count"].eq(0), arel_table[:"#{mode}_rating"].desc, :name)
  }

  def rating(mode) = public_send("#{mode}_rating")
  def games_played(mode) = public_send("#{mode}_games_count")
  def ranked?(mode) = games_played(mode).positive?

  # Days since the last game in a mode, once past the grace period (otherwise nil).
  def idle_days(mode)
    return unless Setting.decay_enabled?

    last = participations.joins(:game).where(games: { mode: Game.modes.fetch(mode) }).maximum("games.played_at")
    return unless last

    days = ((Time.current - last) / 86_400.0).floor
    days if days > Elo::DECAY_GRACE_DAYS
  end

  # Too few games for the rating to be trusted yet.
  def provisional?(mode) = ranked?(mode) && games_played(mode) < Elo::UNSETTLED_GAMES

  def rank(mode)
    return unless ranked?(mode)

    Player.where(Player.arel_table[:"#{mode}_games_count"].gt(0).and(Player.arel_table[:"#{mode}_rating"].gt(rating(mode)))).count + 1
  end
end
