class PlayersController < ApplicationController
  # Everyone's headline stats on one scrolling page, best rating first.
  def index
    net = Ledger.lines.index_by(&:player)
    @overviews = Player.ranked_in(current_mode).map { |player| PlayerOverview.new(player, current_mode, net_cents: net.fetch(player).net_cents) }
  end

  def show
    @player = Player.find(params[:id])
    @results = @player.results(current_mode).reverse
    @bets = Ledger.lines.find { |line| line.player == @player }
    @partnerships = Partnership.for(@player) if current_mode == "doubles"
    @rivalries = Rivalry.for(@player, current_mode)
    @nemesis = @player.nemesis(current_mode)
    @victim = @player.victim(current_mode)
    @upset = @player.biggest_upset(current_mode)
    @blowout = @player.biggest_blowout(current_mode)
    @worst_loss = @player.worst_loss(current_mode)
  end
end
