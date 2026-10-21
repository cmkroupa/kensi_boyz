# Works out the league records from the full game history, in order, and saves
# each time one was set or beaten. Like RatingReplay it runs from scratch after
# any change, so correcting or deleting a game can never leave a stale record.
class RecordReplay
  # A record only counts once it's impressive enough to be worth a mention.
  RECORD_MINIMUMS = {
    "win_streak" => 3, "shutout_streak" => 2, "highest_rating" => 1050,
    "biggest_blowout" => 5, "most_games_in_day" => 4
  }.freeze

  Form = Struct.new(:win_streak, :shutout_streak)

  def self.call
    new.call
  end

  def call
    @breaks = []
    @records = {}
    @form = Hash.new { |hash, key| hash[key] = Form.new(0, 0) }
    @day_counts = Hash.new(0)

    Game.chronologically.preloaded.each { |game| replay(game) }
    save
  end

  private
    def replay(game)
      winners = game.participants_on(game.winner_side)
      losers = game.participants_on(game.loser_side)

      winners.each { |participation| won(participation, game) }
      losers.each { |participation| lost(participation, game) }
      (winners + losers).each { |participation| played(participation, game) }

      record("biggest_blowout", "all", game.margin, game, winners.first.player_id)
      record_upset(game, winners.first.player_id)
    end

    def won(participation, game)
      form = @form[[ participation.player_id, game.mode ]]
      form.win_streak += 1
      record("win_streak", game.mode, form.win_streak, game, participation.player_id)

      if game.score_for(game.loser_side).zero?
        form.shutout_streak += 1
        record("shutout_streak", "all", form.shutout_streak, game, participation.player_id)
      else
        form.shutout_streak = 0
      end
    end

    def lost(participation, game)
      form = @form[[ participation.player_id, game.mode ]]
      form.win_streak = 0
      form.shutout_streak = 0
    end

    def played(participation, game)
      record("highest_rating", game.mode, participation.rating_after, game, participation.player_id)

      day = [ participation.player_id, game.played_at.in_time_zone.to_date ]
      @day_counts[day] += 1
      record("most_games_in_day", "all", @day_counts[day], game, participation.player_id)
    end

    def record(key, scope, value, game, player_id)
      return if value < RECORD_MINIMUMS.fetch(key)
      return if @records[[ key, scope ]] && value <= @records[[ key, scope ]]

      @records[[ key, scope ]] = value
      @breaks << { game_id: game.id, player_id: player_id, key: key, scope: scope, value: value }
    end

    # The upset record is the lowest chance a winner has overcome.
    def record_upset(game, player_id)
      chance = game.chance_for(game.winner_side)
      return if chance >= Game::UPSET_CHANCE
      return if @records[[ "biggest_upset", "all" ]] && chance >= @records[[ "biggest_upset", "all" ]]

      @records[[ "biggest_upset", "all" ]] = chance
      @breaks << { game_id: game.id, player_id: player_id, key: "biggest_upset", scope: "all", value: chance }
    end

    def save
      RecordBreak.transaction do
        RecordBreak.delete_all
        RecordBreak.insert_all(@breaks) if @breaks.any?
      end
    end
end
