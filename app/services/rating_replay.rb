# Rebuilds every rating from scratch by replaying all games in order. Running
# the same code path for every change (new game, deleted game) keeps ratings
# trustworthy and makes fixing a bad entry as simple as deleting it. Ratings of
# players who sit out drift back toward the start, so the saved ratings are
# always as of now (the daily refresh job re-runs this to keep them current).
class RatingReplay
  Standing = Struct.new(:rating, :games, :last_played)

  def self.call
    new.call
  end

  def call
    Player.transaction do
      @decay = Setting.decay_enabled?
      @standings = Hash.new { |hash, key| hash[key] = Standing.new(Elo::BASE_RATING, 0, nil) }
      Game.chronologically.includes(:participations).each { |game| replay(game) }
      decay_all_to(Time.current)
      save_standings
    end
  end

  private
    def replay(game)
      winners = game.participants_on(game.winner_side)
      losers = game.participants_on(game.loser_side)
      (winners + losers).each { |participation| decay(standing_for(game, participation), game.played_at) }

      transfer = Elo.transfer(
        winner_rating: team_rating(game, winners), loser_rating: team_rating(game, losers),
        winner_points: game.score_for(game.winner_side), loser_points: game.score_for(game.loser_side)
      )

      winners.each { |participation| apply(game, participation, transfer) }
      losers.each { |participation| apply(game, participation, -transfer) }
    end

    def standing_for(game, participation)
      @standings[[ participation.player_id, game.mode ]]
    end

    def team_rating(game, participations)
      participations.sum { |p| standing_for(game, p).rating } / participations.size
    end

    def apply(game, participation, change)
      standing = standing_for(game, participation)
      before = standing.rating
      standing.rating += change * Elo.provisional_boost(standing.games)
      standing.games += 1
      standing.last_played = game.played_at
      participation.update_columns(rating_before: before, rating_after: standing.rating)
    end

    # Pulls an idle player's rating toward the start as of the given time.
    def decay(standing, time)
      return unless standing.last_played && @decay

      standing.rating = Elo.decayed(standing.rating, (time - standing.last_played) / 86_400.0)
      standing.last_played = time
    end

    def decay_all_to(time)
      @standings.each_value { |standing| decay(standing, time) }
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
