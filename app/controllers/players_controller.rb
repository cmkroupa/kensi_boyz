class PlayersController < ApplicationController
  def show
    @player = Player.find(params[:id])
    @results = @player.results(current_mode).reverse
    @partnerships = Partnership.for(@player) if current_mode == "doubles"
    @rivalries = Player.where.not(id: @player.id).alphabetically.map { |rival| Rivalry.new(@player, rival, mode: current_mode) }.select { |rivalry| rivalry.games.positive? }
  end
end
