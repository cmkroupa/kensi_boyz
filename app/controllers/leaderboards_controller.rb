class LeaderboardsController < ApplicationController
  RECENT_GAMES = 8

  def show
    if params[:view] == "money"
      @lines = Ledger.lines
      @transfers = Ledger.transfers
    else
      @players = Player.ranked_in(current_mode)
      @top_duos = Partnership.all.first(5) if current_mode == "doubles"
      @recent_games = Game.preloaded.newest_first.limit(RECENT_GAMES)
    end
  end
end
