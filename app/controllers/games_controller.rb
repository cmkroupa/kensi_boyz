class GamesController < ApplicationController
  before_action :set_game, only: %i[ show edit update destroy ]

  def index
    @filter = params[:type]
    games_1v1 = @filter == "2v2" ? [] : Game.order(played_at: :desc).includes(:winner, :loser).to_a
    games_2v2 = @filter == "1v1" ? [] : TeamGame.order(played_at: :desc).includes(winning_team: [ :player1, :player2 ], losing_team: [ :player1, :player2 ]).to_a
    @all_games = (games_1v1 + games_2v2)
                   .sort_by { |g| g.played_at || Time.at(0) }
                   .reverse
  end

  def show
  end

  def new
    @game = Game.new
    @players = Player.order(:name)
  end

  def edit
    @players = Player.order(:name)
  end

  def create
    player1 = Player.find(params[:game][:player1_id])
    player2 = Player.find(params[:game][:player2_id])
    score1 = params[:game][:player1_score].to_i
    score2 = params[:game][:player2_score].to_i

    draw = score1 == score2

    winner, loser, winner_score, loser_score =
      if score1 > score2
        [ player1, player2, score1, score2 ]
      else
        [ player2, player1, score2, score1 ]
      end

    new_p1_elo = EloCalculator.update_elo(winner.elo, loser.elo, winner_score, loser_score)
    new_p2_elo = EloCalculator.update_elo(loser.elo, winner.elo, loser_score, winner_score)

    @game = Game.new(
      winner: winner,
      loser: loser,
      winner_score: winner_score,
      loser_score: loser_score,
      played_at: Time.current
    )

    if @game.save
      if draw
        winner.update!(elo: new_p1_elo)
        loser.update!(elo: new_p2_elo)
        redirect_to players_path, notice: "#{winner.name} and #{loser.name} drew #{winner_score}–#{loser_score}."
      else
        winner.update!(elo: new_p1_elo, wins: winner.wins.to_i + 1)
        loser.update!(elo: new_p2_elo, losses: loser.losses.to_i + 1)
        redirect_to players_path, notice: "#{winner.name} beat #{loser.name} #{winner_score}–#{loser_score}."
      end
    else
      @players = Player.order(:name)
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    @game = Game.new
    @players = Player.order(:name)
    flash.now[:alert] = "Please select valid players."
    render :new, status: :unprocessable_entity
  end

  def update
    respond_to do |format|
      if @game.update(game_params)
        format.html { redirect_to @game, notice: "Game updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @game.destroy!

    respond_to do |format|
      format.html { redirect_to players_path, notice: "Game removed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_game
    @game = Game.find(params.expect(:id))
  end

  def game_params
    params.expect(game: [ :winner_id, :loser_id, :winner_score, :loser_score, :played_at ])
  end
end
