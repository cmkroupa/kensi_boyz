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
      sides = game.participations.group_by(&:side)
      rating_a = team_rating(game, sides["a"])
      rating_b = team_rating(game, sides["b"])

      sides["a"].each { |p| apply(game, p, rating_a, rating_b, game.side_a_score, game.side_b_score) }
      sides["b"].each { |p| apply(game, p, rating_b, rating_a, game.side_b_score, game.side_a_score) }
    end

    def team_rating(game, participations)
      participations.sum { |p| @standings[[ p.player_id, game.mode ]].rating } / participations.size
    end

    def apply(game, participation, team_rating, opponent_rating, points, opponent_points)
      standing = @standings[[ participation.player_id, game.mode ]]
      before = standing.rating
      standing.rating += Elo.delta(rating: team_rating, opponent_rating: opponent_rating,
        points: points, opponent_points: opponent_points, games_played: standing.games)
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
