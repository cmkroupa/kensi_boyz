# Highlights from a player's history in a mode: who owns them, who they own,
# and their biggest upset, blowout and loss.
module Player::Records
  extend ActiveSupport::Concern

  # Rivalries need a few games before they mean anything.
  MIN_RIVALRY_GAMES = 3

  # The opponent with the worst record against this player.
  def nemesis(mode)
    settled_rivalries(mode).select { |rivalry| rivalry.win_rate < 0.5 }
      .min_by { |rivalry| [ rivalry.win_rate, -rivalry.games ] }
  end

  # The opponent this player beats most.
  def victim(mode)
    settled_rivalries(mode).select { |rivalry| rivalry.win_rate > 0.5 }
      .max_by { |rivalry| [ rivalry.win_rate, rivalry.games ] }
  end

  # The win that was least expected, if any win was against the odds.
  def biggest_upset(mode)
    upset = results(mode).select(&:won?).min_by { |result| [ result.game.chance_for(result.side), -result.game_id ] }
    upset if upset && upset.game.chance_for(upset.side) < 0.5
  end

  def biggest_blowout(mode)
    results(mode).select(&:won?).max_by { |result| [ result.game.margin, result.game_id ] }
  end

  def worst_loss(mode)
    results(mode).reject(&:won?).max_by { |result| [ result.game.margin, result.game_id ] }
  end

  TIME_BUCKETS = { "Morning" => 5...12, "Afternoon" => 12...17, "Evening" => 17...22, "Late night" => nil }.freeze
  MIN_BUCKET_GAMES = 5

  # Wins and losses by time of day, Eastern: { "Evening" => [wins, losses] }.
  def time_of_day(mode)
    record = TIME_BUCKETS.keys.index_with { [ 0, 0 ] }
    results(mode).each do |result|
      bucket = time_bucket(result.game.played_at.in_time_zone.hour)
      record[bucket][result.won? ? 0 : 1] += 1
    end
    record
  end

  # The bucket with the best win rate, once it has enough games to mean anything
  # and a winning record.
  def best_time_of_day(mode)
    time_of_day(mode).select { |_, (wins, losses)| wins + losses >= MIN_BUCKET_GAMES && wins > losses }
      .max_by { |_, (wins, losses)| wins.fdiv(wins + losses) }&.first
  end

  private
    def time_bucket(hour)
      TIME_BUCKETS.find { |_, hours| hours&.cover?(hour) }&.first || "Late night"
    end

    def settled_rivalries(mode)
      Rivalry.for(self, mode).select { |rivalry| rivalry.games >= MIN_RIVALRY_GAMES }
    end
end
