# Re-runs the rating replay so idle players' decay shows up even when nobody logs a game.
class RatingRefreshJob < ApplicationJob
  def perform
    Game.rebuild_derived_data
  end
end
