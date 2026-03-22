json.extract! player, :id, :name, :elo, :wins, :losses, :created_at, :updated_at
json.url player_url(player, format: :json)
