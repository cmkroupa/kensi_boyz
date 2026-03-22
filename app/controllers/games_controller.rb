class GamesController < ApplicationController
  before_action :set_game, only: %i[ show edit update destroy ]

  def index
    games_1v1 = Game.order(played_at: :desc)
                    .includes(:winner, :loser)
    games_2v2 = TeamGame.order(played_at: :desc)
                        .includes(winning_team: [ :player1, :player2 ], losing_team: [ :player1, :player2 ])
    @all_games = (games_1v1.to_a + games_2v2.to_a)
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
  end

  def create
    player1 = Player.find(params[:game][:player1_id])
    player2 = Player.find(params[:game][:player2_id])
    score1 = params[:game][:player1_score].to_i
    score2 = params[:game][:player2_score].to_i

    winner, loser, winner_score, loser_score =
      if score1 >= score2
        [ player1, player2, score1, score2 ]
      else
        [ player2, player1, score2, score1 ]
      end

    new_winner_elo = EloCalculator.update_elo(winner.elo, loser.elo, winner_score, loser_score)
    new_loser_elo  = EloCalculator.update_elo(loser.elo, winner.elo, loser_score, winner_score)

    @game = Game.new(
      winner: winner,
      loser: loser,
      winner_score: winner_score,
      loser_score: loser_score,
      played_at: Time.current
    )

    if @game.save
      winner.update!(elo: new_winner_elo, wins: winner.wins.to_i + 1)
      loser.update!(elo: new_loser_elo, losses: loser.losses.to_i + 1)
      redirect_to players_path, notice: "#{winner.name} beat #{loser.name} #{winner_score}–#{loser_score}."
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
