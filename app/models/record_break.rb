# Each time a league record was set or beaten, in order. The latest row for a
# key and scope is the current record. Rebuilt by AchievementReplay.
class RecordBreak < ApplicationRecord
  LABELS = {
    "win_streak" => "Longest win streak",
    "shutout_streak" => "Longest shutout streak",
    "highest_rating" => "Highest rating",
    "biggest_blowout" => "Biggest blowout",
    "biggest_upset" => "Biggest upset",
    "most_games_in_day" => "Most games in a day"
  }.freeze

  belongs_to :game
  belongs_to :player, optional: true

  validates :key, inclusion: { in: LABELS.keys }

  # The record as it stands now: the newest break for each key and scope.
  def self.current
    order(:id).to_a.group_by { |record| [ record.key, record.scope ] }.transform_values(&:last).values
  end

  def label
    scope == "all" ? LABELS.fetch(key) : "#{LABELS.fetch(key)} (#{scope == 'singles' ? '1v1' : '2v2'})"
  end
end
