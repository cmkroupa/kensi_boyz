class LeaderboardsController < ApplicationController
  RECENT_GAMES = 8
  VIEWS = %w[ ratings money activity ].freeze

  def show
    @view = VIEWS.include?(params[:view]) ? params[:view] : "ratings"

    case @view
    when "money"
      @lines = Ledger.lines
    when "activity"
      @activity = Activity.new(Game.chronologically)
    else
      @players = Player.ranked_in(current_mode)
      @top_duos = Partnership.all.first(5) if current_mode == "doubles"
      @recent_games = Game.preloaded.newest_first.limit(RECENT_GAMES)
    end
  end
end
