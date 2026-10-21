class PlayersController < ApplicationController
  before_action :require_admin, only: %i[ create update ]

  # Everyone's headline stats on one scrolling page, best rating first.
  def index
    net = Ledger.lines.index_by(&:player)
    @overviews = Player.ranked_in(current_mode).map { |player| PlayerOverview.new(player, current_mode, net_cents: net.fetch(player).net_cents) }
  end

  def create
    player = Player.new(params.expect(player: :name))
    redirect_to admin_path, player.save ? { notice: "#{player.name} added." } : { alert: player.errors.full_messages.to_sentence }
  end

  def update
    player = Player.find(params[:id])
    redirect_to admin_path, player.update(params.expect(player: :name)) ? { notice: "Renamed to #{player.name}." } : { alert: player.errors.full_messages.to_sentence }
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
