class PlayersController < ApplicationController
  before_action :set_player, only: %i[ show edit update destroy ]

  def index
    @players = Player.order(elo: :desc)
  end

  def show
    @rank = Player.where("elo > ?", @player.elo).count + 1
    @recent_games = Game.where("winner_id = ? OR loser_id = ?", @player.id, @player.id)
                        .order(played_at: :desc)
                        .limit(10)
                        .includes(:winner, :loser)
    my_team_ids = Team.where("player1_id = ? OR player2_id = ?", @player.id, @player.id).pluck(:id)
    @recent_team_games = TeamGame.where("winning_team_id IN (?) OR losing_team_id IN (?)", my_team_ids, my_team_ids)
                                 .order(played_at: :desc)
                                 .limit(10)
                                 .includes(winning_team: [ :player1, :player2 ], losing_team: [ :player1, :player2 ])
  end

  def new
    @player = Player.new
  end

  def edit
  end

  def create
    @player = Player.new(player_params)

    respond_to do |format|
      if @player.save
        format.html { redirect_to players_path, notice: "#{@player.name} added with ELO #{@player.elo}." }
        format.json { render :show, status: :created, location: @player }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @player.update(player_params)
        format.html { redirect_to players_path, notice: "#{@player.name} updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @player }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @player.destroy!

    respond_to do |format|
      format.html { redirect_to players_path, notice: "#{@player.name} removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_player
    @player = Player.find(params.expect(:id))
  end

  def player_params
    params.expect(player: [ :name ])
  end
end
