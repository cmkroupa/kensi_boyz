# Works out every badge and league record from the full game history, in order,
# and saves the result. Like RatingReplay it runs from scratch after any change,
# so correcting or deleting a game can never leave an unearned badge behind.
class AchievementReplay
  GAMES_PLAYED = { 10 => "games_10", 25 => "games_25", 50 => "games_50", 100 => "games_100" }.freeze
  WIN_STREAKS = { 3 => "win_streak_3", 5 => "win_streak_5", 10 => "win_streak_10" }.freeze
  RATING_CLUBS = { 1100 => "rating_1100", 1200 => "rating_1200" }.freeze
  GIANT_KILLER_CHANCE = 0.25
  BIG_BET_CENTS = 2000
  TOP_PLAYER_MIN_GAMES = 3

  # A record only counts once it's impressive enough to be worth a mention.
  RECORD_MINIMUMS = {
    "win_streak" => 3, "shutout_streak" => 2, "highest_rating" => 1050,
    "biggest_blowout" => 5, "most_games_in_day" => 4
  }.freeze

  Form = Struct.new(:win_streak, :loss_streak, :shutout_streak, :one_point_wins, :partner_wins)

  def self.call
    new.call
  end

  def call
    @awarded = Set.new
    @awards = []
    @breaks = []
    @records = {}
    @form = Hash.new { |hash, key| hash[key] = Form.new(0, 0, 0, 0, Hash.new(0)) }
    @games_played = Hash.new(0)
    @mode_games = Hash.new(0)
    @bet_streak = Hash.new(0)
    @ratings = {}
    @day_counts = Hash.new(0)

    Game.chronologically.preloaded.each { |game| replay(game) }
    save
  end

  private
    def replay(game)
      winners = game.participants_on(game.winner_side)
      losers = game.participants_on(game.loser_side)
      context = { game: game, chance: game.chance_for(game.winner_side), top: top_rated_before(game),
        winner_points: game.score_for(game.winner_side), loser_points: game.score_for(game.loser_side) }

      winners.each { |participation| won(participation, context) }
      losers.each { |participation| lost(participation, context) }
      (winners + losers).each { |participation| played(participation, game) }

      record("biggest_blowout", "all", game.margin, game, winners.first.player_id)
      record_upset(game, context[:chance], winners.first.player_id)
    end

    def won(participation, context)
      game = context[:game]
      player_id = participation.player_id
      form = @form[[ player_id, game.mode ]]

      award(player_id, "comeback", game) if form.loss_streak >= 3
      form.win_streak += 1
      form.loss_streak = 0
      WIN_STREAKS.each { |length, key| award(player_id, key, game) if form.win_streak >= length }
      award(player_id, "first_win", game)
      record("win_streak", game.mode, form.win_streak, game, player_id)

      if context[:loser_points].zero?
        form.shutout_streak += 1
        award(player_id, "shutout", game)
        award(player_id, "shutout_streak_2", game) if form.shutout_streak >= 2
        record("shutout_streak", "all", form.shutout_streak, game, player_id)
      else
        form.shutout_streak = 0
      end

      if game.margin == 1 && context[:winner_points] >= 7
        form.one_point_wins += 1
        award(player_id, "nail_biter", game)
        award(player_id, "clutch", game) if form.one_point_wins >= 3
      end

      award(player_id, "giant_killer", game) if context[:chance] < GIANT_KILLER_CHANCE
      award(player_id, "beat_the_best", game) if game.participants_on(game.loser_side).any? { |loser| loser.player_id == context[:top] }
      count_partner_win(participation, form, game)
      count_bet_win(participation, game)
    end

    def lost(participation, context)
      game = context[:game]
      form = @form[[ participation.player_id, game.mode ]]
      form.win_streak = 0
      form.shutout_streak = 0
      form.loss_streak += 1
      award(participation.player_id, "got_zeroed", game) if participation.points.zero?
      @bet_streak[participation.player_id] = 0 if game.bet?
    end

    def played(participation, game)
      player_id = participation.player_id
      @games_played[player_id] += 1
      @mode_games[[ player_id, game.mode ]] += 1
      @ratings[[ player_id, game.mode ]] = participation.rating_after

      GAMES_PLAYED.each { |count, key| award(player_id, key, game) if @games_played[player_id] >= count }
      RATING_CLUBS.each { |rating, key| award(player_id, key, game) if participation.rating_after >= rating }
      record("highest_rating", game.mode, participation.rating_after, game, player_id)

      day = [ player_id, game.played_at.in_time_zone.to_date ]
      @day_counts[day] += 1
      record("most_games_in_day", "all", @day_counts[day], game, player_id)
    end

    def count_partner_win(participation, form, game)
      return unless game.doubles?

      partner = participation.teammates.first.player_id
      form.partner_wins[partner] += 1
      award(participation.player_id, "duo_5", game) if form.partner_wins[partner] >= 5
    end

    def count_bet_win(participation, game)
      return unless game.bet?

      @bet_streak[participation.player_id] += 1
      award(participation.player_id, "bet_streak_3", game) if @bet_streak[participation.player_id] >= 3
      award(participation.player_id, "big_bet", game) if game.winnings_for(participation.side) >= BIG_BET_CENTS
    end

    # The best-rated player in the mode going into the game, once they've played enough to count.
    def top_rated_before(game)
      ratings = @ratings.select { |(_, mode), _| mode == game.mode }.transform_keys(&:first)
      game.participations.each { |participation| ratings[participation.player_id] = participation.rating_before }
      top, = ratings.select { |player_id, _| @mode_games[[ player_id, game.mode ]] >= TOP_PLAYER_MIN_GAMES }.max_by { |_, rating| rating }
      top
    end

    def award(player_id, key, game)
      scope = Achievement::CATALOG.fetch(key)[:scope] == :mode ? game.mode : "all"
      return unless @awarded.add?([ player_id, key, scope ])

      @awards << { player_id: player_id, game_id: game.id, key: key, scope: scope }
    end

    def record(key, scope, value, game, player_id)
      return if value < RECORD_MINIMUMS.fetch(key)
      return if @records[[ key, scope ]] && value <= @records[[ key, scope ]]

      @records[[ key, scope ]] = value
      @breaks << { game_id: game.id, player_id: player_id, key: key, scope: scope, value: value }
    end

    # The upset record is the lowest chance a winner has overcome.
    def record_upset(game, chance, player_id)
      return if chance >= Game::UPSET_CHANCE
      return if @records[[ "biggest_upset", "all" ]] && chance >= @records[[ "biggest_upset", "all" ]]

      @records[[ "biggest_upset", "all" ]] = chance
      @breaks << { game_id: game.id, player_id: player_id, key: "biggest_upset", scope: "all", value: chance }
    end

    def save
      Achievement.transaction do
        Achievement.delete_all
        RecordBreak.delete_all
        Achievement.insert_all(@awards) if @awards.any?
        RecordBreak.insert_all(@breaks) if @breaks.any?
      end
    end
end
