class PlaysController < ApplicationController
  # Where games are logged: pick the teams, add a bet if there is one, enter the score once it's played.
  def show
    @players = Player.alphabetically
    @game = rematch || Game.new(mode: current_mode)
  end

  private
    # Rematch reloads the teams of the last game logged.
    def rematch
      last = Game.preloaded.newest_first.first if params[:rematch]
      return unless last

      Game.new(mode: last.mode,
        side_a_player_ids: last.participants_on("a").map(&:player_id),
        side_b_player_ids: last.participants_on("b").map(&:player_id))
    end
end
