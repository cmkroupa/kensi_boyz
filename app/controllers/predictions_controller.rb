class PredictionsController < ApplicationController
  def show
    @players = Player.alphabetically
    @side_a_ids = ids_for(:side_a_player_ids)
    @side_b_ids = ids_for(:side_b_player_ids)
    return if @side_a_ids.empty? && @side_b_ids.empty?

    prediction = Prediction.new(mode: current_mode, side_a: @players.select { |p| @side_a_ids.include?(p.id) },
      side_b: @players.select { |p| @side_b_ids.include?(p.id) })
    @prediction = prediction if prediction.valid?
    @bet_cents = params[:bet_dollars].to_i.clamp(0, Game::MAX_BET_CENTS / 100) * 100
    @error = "Pick #{Game::PLAYERS_PER_SIDE[current_mode]} per team, nobody on both." unless @prediction
  end

  private
    def ids_for(key)
      Array(params[key]).compact_blank.map(&:to_i)
    end
end
