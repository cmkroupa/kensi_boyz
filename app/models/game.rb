class Game < ApplicationRecord
  PLAYERS_PER_SIDE = { "singles" => 1, "doubles" => 2 }.freeze
  MAX_BET_CENTS = 99_900
  UPSET_CHANCE = 0.30

  enum :mode, { singles: 0, doubles: 1 }

  has_many :participations, dependent: :destroy
  has_many :players, through: :participations
  has_many :debts, dependent: :destroy
  has_many :achievements, dependent: :destroy
  has_many :record_breaks, dependent: :destroy

  attribute :played_at, default: -> { Time.current }

  # Players for each side are submitted as ids and turned into participations on create.
  attr_writer :side_a_player_ids, :side_b_player_ids

  validates :side_a_score, :side_b_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :mode, presence: true
  validates :underdog_stake_cents, numericality: { only_integer: true, in: 0..MAX_BET_CENTS }
  validate :scores_differ
  validate :sides_are_valid

  before_create :lock_bet_terms
  after_create :create_participations
  after_save { Game.rebuild_derived_data }
  after_save :sync_debts
  after_destroy { Game.rebuild_derived_data }

  scope :chronologically, -> { order(:played_at, :id) }
  scope :newest_first, -> { order(played_at: :desc, id: :desc) }
  scope :preloaded, -> { includes(participations: :player) }
  scope :with_bet, -> { where(underdog_stake_cents: 1..) }

  def side_a_player_ids = Array(@side_a_player_ids).compact_blank.map(&:to_i)
  def side_b_player_ids = Array(@side_b_player_ids).compact_blank.map(&:to_i)

  # The bet is entered in whole dollars and is what the underdog puts up.
  # Everything computed by replaying the whole history: ratings, then badges and records.
  def self.rebuild_derived_data
    RatingReplay.call
    AchievementReplay.call
  end

  def bet_dollars = underdog_stake_cents / 100
  def bet_dollars=(dollars)
    self.underdog_stake_cents = dollars.to_i * 100
  end

  def bet? = underdog_stake_cents.positive?

  # Per player: what a side risks, what it wins, and how it came out.
  def stake_for(side) = side == favorite_side ? favorite_stake_cents : underdog_stake_cents
  def winnings_for(side) = stake_for(side == "a" ? "b" : "a")
  def bet_result_for(side) = side == winner_side ? winnings_for(side) : -stake_for(side)

  def winner_side
    side_a_score > side_b_score ? "a" : "b"
  end

  def loser_side
    winner_side == "a" ? "b" : "a"
  end

  def score_for(side)
    side == "a" ? side_a_score : side_b_score
  end

  def margin
    (side_a_score - side_b_score).abs
  end

  # Win chance for a side going into the game, from the ratings it had then.
  def chance_for(side)
    other = side == "a" ? "b" : "a"
    Elo.expected(average_rating_before(side), average_rating_before(other))
  end

  Breakdown = Struct.new(:winner_rating, :loser_rating, :chance, :margin_multiplier, :transfer)

  # The numbers behind this game's rating change (before any new-player boost).
  def elo_breakdown
    winner_rating = average_rating_before(winner_side)
    loser_rating = average_rating_before(loser_side)
    Breakdown.new(winner_rating, loser_rating, Elo.expected(winner_rating, loser_rating),
      Elo.margin_multiplier(winner_rating - loser_rating, margin),
      Elo.transfer(winner_rating: winner_rating, loser_rating: loser_rating,
        winner_points: score_for(winner_side), loser_points: score_for(loser_side)))
  end

  # A win from a side that was given less than a 30% chance.
  def upset? = chance_for(winner_side) < UPSET_CHANCE

  def participants_on(side)
    participations.select { |participation| participation.side == side }
  end

  private
    def average_rating_before(side)
      participants_on(side).sum(&:rating_before) / participants_on(side).size
    end

    # Odds come from the ratings going into the game, and are fixed once saved.
    def lock_bet_terms
      return unless bet?

      terms = Moneyline.terms(chance_a: Elo.expected(team_rating(side_a_player_ids), team_rating(side_b_player_ids)),
        underdog_stake_cents: underdog_stake_cents)
      self.favorite_side = terms.favorite_side
      self.favorite_stake_cents = terms.favorite_stake_cents
    end

    # Each loser owes one winner (paired in id order) what they risked. Debts that
    # still match keep their paid status; the rest are replaced.
    def sync_debts
      wanted = debt_terms
      debts.reload.each { |debt| debt.destroy unless wanted.delete([ debt.debtor_id, debt.creditor_id, debt.cents ]) }
      wanted.each { |debtor_id, creditor_id, cents| debts.create!(debtor_id: debtor_id, creditor_id: creditor_id, cents: cents) }
      debts.reset
    end

    def debt_terms
      return [] unless bet?

      losers = participants_on(loser_side).map(&:player_id).sort
      winners = participants_on(winner_side).map(&:player_id).sort
      losers.zip(winners).map { |loser, winner| [ loser, winner, winnings_for(winner_side) ] }
    end

    def team_rating(ids)
      Player.where(id: ids).sum { |player| player.rating(mode) } / ids.size
    end

    def scores_differ
      errors.add(:base, "Scores can't be tied") if side_a_score && side_a_score == side_b_score
    end

    def sides_are_valid
      return unless new_record? && mode

      ids = side_a_player_ids + side_b_player_ids
      size = PLAYERS_PER_SIDE.fetch(mode)
      errors.add(:base, "Pick #{size} per side") unless side_a_player_ids.size == size && side_b_player_ids.size == size
      errors.add(:base, "A player can only be on one side") unless ids.uniq.size == ids.size
      errors.add(:base, "Unknown player") unless Player.where(id: ids).count == ids.uniq.size
    end

    def create_participations
      side_a_player_ids.each { |id| participations.create!(player_id: id, side: "a") }
      side_b_player_ids.each { |id| participations.create!(player_id: id, side: "b") }
    end
end
