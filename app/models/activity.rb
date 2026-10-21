# When games get played: how many per day, which hours and weekdays are busiest,
# and how long the group has kept a daily habit going. Times are Eastern.
class Activity
  DAYS = 30

  attr_reader :games

  def initialize(games)
    @games = games.to_a
  end

  def total = games.size

  # [[date, count]] for the last 30 days, today last.
  def per_day(days = DAYS)
    counts = games_by_day
    ((Time.zone.today - (days - 1))..Time.zone.today).map { |date| [ date, counts.fetch(date, 0) ] }
  end

  # Games started in each hour of the day, 0 to 23.
  def by_hour
    counts = games.map { |game| game.played_at.in_time_zone.hour }.tally
    (0..23).map { |hour| counts.fetch(hour, 0) }
  end

  # Monday first.
  def by_weekday
    counts = games.map { |game| game.played_at.in_time_zone.to_date.cwday }.tally
    (1..7).map { |day| counts.fetch(day, 0) }
  end

  def busiest_day
    games_by_day.max_by { |date, count| [ count, date ] }
  end

  def peak_hour
    counts = by_hour
    counts.each_index.max_by { |hour| [ counts[hour], -hour ] } if counts.any?(&:positive?)
  end

  # Days in a row, ending today or yesterday, with at least one game.
  def day_streak
    played = games_by_day
    day = played.key?(Time.zone.today) ? Time.zone.today : Time.zone.today - 1
    streak = 0
    while played.key?(day)
      streak += 1
      day -= 1
    end
    streak
  end

  private
    def games_by_day
      @games_by_day ||= games.map { |game| game.played_at.in_time_zone.to_date }.tally
    end
end
