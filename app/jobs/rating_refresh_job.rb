# Re-runs the rating replay so idle players' decay shows up even when nobody logs a game.
class RatingRefreshJob < ApplicationJob
  def perform
    RatingReplay.call
  end
end
