class PlayersController < ApplicationController
  def show
    @player = Player.find(params[:id])
    @results = @player.results(current_mode).reverse
    @bets = Ledger.lines.find { |line| line.player == @player }
    @partnerships = Partnership.for(@player) if current_mode == "doubles"
    @rivalries = Rivalry.for(@player, current_mode)
    @time_of_day = @player.time_of_day(current_mode)
    @best_time = @player.best_time_of_day(current_mode)
    @nemesis = @player.nemesis(current_mode)
    @victim = @player.victim(current_mode)
    @upset = @player.biggest_upset(current_mode)
    @blowout = @player.biggest_blowout(current_mode)
    @worst_loss = @player.worst_loss(current_mode)
  end
end
