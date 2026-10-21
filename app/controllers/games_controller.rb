class GamesController < ApplicationController
  PER_PAGE = 30

  before_action :require_admin, only: %i[ edit update destroy ]

  def index
    load_history
  end

  def show
    @game = Game.preloaded.find(params[:id])
  end

  def create
    @game = Game.new(game_params)
    if @game.save
      redirect_to @game, notice: "Game logged."
    else
      @players = Player.alphabetically
      render "plays/show", status: :unprocessable_content
    end
  end

  def edit
    @game = Game.preloaded.find(params[:id])
  end

  def update
    @game = Game.preloaded.find(params[:id])
    if @game.update(params.expect(game: %i[ side_a_score side_b_score ]))
      redirect_to @game, notice: "Score updated and ratings recalculated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    Game.find(params[:id]).destroy
    redirect_to games_path, notice: "Game deleted and ratings recalculated."
  end

  private
    def load_history
      @player = Player.find_by(id: params[:player_id])
      @mode = params[:mode] if Game.modes.key?(params[:mode])
      scope = Game.preloaded.newest_first
      scope = scope.where(mode: @mode) if @mode
      scope = scope.where(id: @player.games) if @player
      @page = [ params[:page].to_i, 1 ].max
      @games = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
      @more = @games.slice!(PER_PAGE..).present?
    end

    def game_params
      params.expect(game: [ :mode, :side_a_score, :side_b_score, :bet_dollars, side_a_player_ids: [], side_b_player_ids: [] ])
    end
end
