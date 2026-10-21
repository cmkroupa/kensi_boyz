class Game < ApplicationRecord
  PLAYERS_PER_SIDE = { "singles" => 1, "doubles" => 2 }.freeze

  enum :mode, { singles: 0, doubles: 1 }

  has_many :participations, dependent: :destroy
  has_many :players, through: :participations

  attribute :played_at, default: -> { Time.current }

  # Players for each side are submitted as ids and turned into participations on create.
  attr_writer :side_a_player_ids, :side_b_player_ids

  validates :side_a_score, :side_b_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :mode, presence: true
  validate :scores_differ
  validate :sides_are_valid

  after_create :create_participations
  after_save { RatingReplay.call }
  after_destroy { RatingReplay.call }

  scope :chronologically, -> { order(:played_at, :id) }
  scope :newest_first, -> { order(played_at: :desc, id: :desc) }
  scope :preloaded, -> { includes(participations: :player) }

  def side_a_player_ids = Array(@side_a_player_ids).compact_blank.map(&:to_i)
  def side_b_player_ids = Array(@side_b_player_ids).compact_blank.map(&:to_i)

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

  def participants_on(side)
    participations.select { |participation| participation.side == side }
  end

  private
    def average_rating_before(side)
      participants_on(side).sum(&:rating_before) / participants_on(side).size
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
