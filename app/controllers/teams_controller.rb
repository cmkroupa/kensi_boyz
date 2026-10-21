class TeamsController < ApplicationController
  def show
    players = Player.where(id: params[:id].split("-")).to_a
    @partnership = Partnership.between(*players) if players.size == 2
    raise ActiveRecord::RecordNotFound unless @partnership
  end
end
