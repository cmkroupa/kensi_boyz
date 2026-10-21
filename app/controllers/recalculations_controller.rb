# Rebuilds ratings and records from the full game history.
class RecalculationsController < ApplicationController
  before_action :require_admin

  def create
    Game.rebuild_derived_data
    redirect_to admin_path, notice: "Ratings and records recalculated."
  end
end
