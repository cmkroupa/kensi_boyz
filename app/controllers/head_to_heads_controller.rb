class HeadToHeadsController < ApplicationController
  def show
    @players = Player.alphabetically
    @side_a_ids = ids_for(:side_a_player_ids)
    @side_b_ids = ids_for(:side_b_player_ids)
    return if @side_a_ids.empty? && @side_b_ids.empty?

    head_to_head = HeadToHead.new(mode: current_mode, side_a: @players.select { |p| @side_a_ids.include?(p.id) },
      side_b: @players.select { |p| @side_b_ids.include?(p.id) })
    @head_to_head = head_to_head if head_to_head.valid?
    @error = "Pick #{Game::PLAYERS_PER_SIDE[current_mode]} per team, nobody on both." unless @head_to_head
  end

  private
    def ids_for(key)
      Array(params[key]).compact_blank.map(&:to_i)
    end
end
