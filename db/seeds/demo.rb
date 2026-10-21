# Random games for eyeballing the whole app. Never runs in production.
# DEMO_DATA=1 bin/rails db:seed      add games on top of whatever exists
# DEMO_DATA=reset bin/rails db:seed  wipe all games first, then add fresh ones
abort "Refusing to seed demo data in production" if Rails.env.production?

Game.destroy_all if ENV["DEMO_DATA"] == "reset"

random = Random.new
players = Player.all.to_a
played_at = 60.days.ago

# Give each player a hidden skill so ratings spread out like real life.
skill = players.to_h { |player| [ player.id, random.rand(-1.5..1.5) ] }

# The better team usually wins, but upsets and close games both happen.
def final_score(strength_gap, random)
  favorite_wins = random.rand < 1 / (1 + Math.exp(-strength_gap))
  loser = [ [ (8 * (1 - 1 / (1 + Math.exp(strength_gap.abs))) * 1.6 + random.rand(-2..2)).round, 0 ].max, 7 ].min
  favorite_wins == strength_gap.positive? ? [ 8, loser ] : [ loser, 8 ]
end

120.times do
  played_at += random.rand(2..9).hours
  mode = random.rand < 0.5 ? "singles" : "doubles"
  picked = players.sample(mode == "singles" ? 2 : 4, random: random)
  side_a, side_b = picked.each_slice(picked.size / 2).to_a
  gap = side_a.sum { |p| skill[p.id] } - side_b.sum { |p| skill[p.id] }
  score_a, score_b = final_score(gap, random)

  Game.create!(mode: mode, played_at: played_at, side_a_score: score_a, side_b_score: score_b,
    side_a_player_ids: side_a.map(&:id), side_b_player_ids: side_b.map(&:id))
end

puts "Seeded #{Game.count} demo games"
