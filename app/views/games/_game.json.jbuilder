json.extract! game, :id, :winner_id, :loser_id, :winner_score, :loser_score, :played_at, :created_at, :updated_at
json.url game_url(game, format: :json)
