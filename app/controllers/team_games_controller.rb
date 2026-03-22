class TeamGamesController < ApplicationController
  def new
    @players = Player.order(:name)
  end

  def create
    p1 = Player.find(params[:team1_player1_id])
    p2 = Player.find(params[:team1_player2_id])
    p3 = Player.find(params[:team2_player1_id])
    p4 = Player.find(params[:team2_player2_id])
    score1 = params[:team1_score].to_i
    score2 = params[:team2_score].to_i

    team1 = Team.find_or_create_for(p1, p2)
    team2 = Team.find_or_create_for(p3, p4)

    team1_avg = team1.avg_elo
    team2_avg = team2.avg_elo

    winning_team, losing_team, winner_score, loser_score =
      if score1 >= score2
        [ team1, team2, score1, score2 ]
      else
        [ team2, team1, score2, score1 ]
      end

    winning_players = winning_team.players
    losing_players  = losing_team.players
    winning_avg     = winning_team.avg_elo
    losing_avg      = losing_team.avg_elo

    team_game = TeamGame.new(
      winning_team: winning_team,
      losing_team: losing_team,
      winner_score: winner_score,
      loser_score: loser_score,
      played_at: Time.current
    )

    if team_game.save
      winning_players.each do |p|
        new_elo = EloCalculator.update_elo(p.elo, losing_avg, winner_score, loser_score)
        p.update!(elo: new_elo, wins: p.wins.to_i + 1)
      end
      losing_players.each do |p|
        new_elo = EloCalculator.update_elo(p.elo, winning_avg, loser_score, winner_score)
        p.update!(elo: new_elo, losses: p.losses.to_i + 1)
      end

      redirect_to players_path,
        notice: "#{winning_players.map(&:name).join(' & ')} beat #{losing_players.map(&:name).join(' & ')} #{winner_score}–#{loser_score}."
    else
      @players = Player.order(:name)
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    @players = Player.order(:name)
    flash.now[:alert] = "Please select valid players."
    render :new, status: :unprocessable_entity
  end
end
