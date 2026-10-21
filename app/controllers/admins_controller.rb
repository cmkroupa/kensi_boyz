# The admin page: switches, backup status, how well the predictor is doing, and player upkeep.
class AdminsController < ApplicationController
  before_action :require_admin

  def show
    @players = Player.alphabetically
    @accuracy = PredictorAccuracy.new
    @decay = Setting.decay_enabled?
  end
end
