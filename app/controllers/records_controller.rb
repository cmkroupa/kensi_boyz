class RecordsController < ApplicationController
  def show
    @records = RecordBreak.includes(:player, game: { participations: :player }).current
      .sort_by { |record| RecordBreak::LABELS.keys.index(record.key) }
  end
end
