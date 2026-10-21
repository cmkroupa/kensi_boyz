class Participation < ApplicationRecord
  enum :side, { a: 0, b: 1 }

  belongs_to :game
  belongs_to :player

  def won?
    game.winner_side == side
  end

  def delta
    rating_after - rating_before
  end

  def bet_result_cents
    game.bet? ? game.bet_result_for(side) : 0
  end

  def points
    game.score_for(side)
  end

  def opponent_points
    game.score_for(side == "a" ? "b" : "a")
  end

  def teammates
    game.participants_on(side) - [ self ]
  end

  def opponents
    game.participants_on(side == "a" ? "b" : "a")
  end
end
