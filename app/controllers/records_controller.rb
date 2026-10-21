class RecordsController < ApplicationController
  RECENT = 10

  def show
    @records = RecordBreak.includes(:player, game: { participations: :player }).current
      .sort_by { |record| RecordBreak::LABELS.keys.index(record.key) }
    @recent_achievements = Achievement.includes(:player, :game).order(id: :desc).limit(RECENT)
  end
end
