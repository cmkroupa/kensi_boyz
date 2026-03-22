module EloCalculator
  K = 32

  def self.expected(player_elo, opponent_elo)
    exp = (opponent_elo - player_elo) / 400.0
    1.0 / (1.0 + 10.0**exp)
  end

  def self.update_elo(player_elo, opponent_elo, player_score, opponent_score)
    expected_win = expected(player_elo, opponent_elo)
    score_diff = (player_score - opponent_score).abs
    margin_multiplier = Math.log(score_diff + 1)
    actual_score = if player_score > opponent_score
                     1.0
    elsif player_score < opponent_score
                     0.0
    else
                     0.5
    end
    new_rating = player_elo + (K * margin_multiplier) * (actual_score - expected_win)
    [ new_rating.round, 0 ].max
  end
end
