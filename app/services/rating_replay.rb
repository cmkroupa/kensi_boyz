# Rebuilds every rating from scratch by replaying all games in order. Running
# the same code path for every change (new game, deleted game) keeps ratings
# trustworthy and makes fixing a bad entry as simple as deleting it.
class RatingReplay
  Standing = Struct.new(:rating, :games)

  def self.call
    new.call
  end

  def call
    Player.transaction do
      @standings = Hash.new { |hash, key| hash[key] = Standing.new(Elo::BASE_RATING, 0) }
      Game.chronologically.includes(:participations).each { |game| replay(game) }
      save_standings
    end
  end

  private
    def replay(game)
      winners = game.participants_on(game.winner_side)
      losers = game.participants_on(game.loser_side)

      transfer = Elo.transfer(
        winner_rating: team_rating(game, winners), loser_rating: team_rating(game, losers),
        winner_points: game.score_for(game.winner_side), loser_points: game.score_for(game.loser_side)
      )

      winners.each { |participation| apply(game, participation, transfer) }
      losers.each { |participation| apply(game, participation, -transfer) }
    end

    def team_rating(game, participations)
      participations.sum { |p| @standings[[ p.player_id, game.mode ]].rating } / participations.size
    end

    def apply(game, participation, change)
      standing = @standings[[ participation.player_id, game.mode ]]
      before = standing.rating
      standing.rating += change * Elo.provisional_boost(standing.games)
      standing.games += 1
      participation.update_columns(rating_before: before, rating_after: standing.rating)
    end

    def save_standings
      Player.find_each do |player|
        player.update_columns(
          singles_rating: @standings[[ player.id, "singles" ]].rating,
          singles_games_count: @standings[[ player.id, "singles" ]].games,
          doubles_rating: @standings[[ player.id, "doubles" ]].rating,
          doubles_games_count: @standings[[ player.id, "doubles" ]].games
        )
      end
    end
end
