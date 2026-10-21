# A badge a player earned, and the game that earned it. Rebuilt from the whole
# game history after every change by AchievementReplay, so edits and deletes
# never leave a stale badge behind.
class Achievement < ApplicationRecord
  CATALOG = {
    "win_streak_5" => { name: "On fire", description: "Win 5 in a row", scope: :mode },
    "win_streak_10" => { name: "Unstoppable", description: "Win 10 in a row", scope: :mode },
    "shutout" => { name: "Shutout", description: "Win without the other side scoring", scope: :mode },
    "shutout_streak_2" => { name: "Clean sheets", description: "Two shutouts in a row", scope: :mode },
    "clutch" => { name: "Clutch", description: "Win three games by a single point", scope: :mode },
    "giant_killer" => { name: "Giant killer", description: "Win with under a 25% chance", scope: :mode },
    "beat_the_best" => { name: "Beat the best", description: "Beat the top-rated player", scope: :mode },
    "rating_1100" => { name: "1100 club", description: "Reach a rating of 1100", scope: :mode },
    "rating_1200" => { name: "1200 club", description: "Reach a rating of 1200", scope: :mode },
    "duo_5" => { name: "Dynamic duo", description: "Win 5 games with the same partner", scope: :mode },
    "bet_streak_3" => { name: "Hot hand", description: "Win 3 bets in a row", scope: :all },
    "big_bet" => { name: "High roller", description: "Win $20 or more on a single bet", scope: :all }
  }.freeze

  belongs_to :player
  belongs_to :game

  validates :key, inclusion: { in: CATALOG.keys }

  def name = CATALOG.fetch(key)[:name]
  def description = CATALOG.fetch(key)[:description]
  def mode_scoped? = CATALOG.fetch(key)[:scope] == :mode
end
