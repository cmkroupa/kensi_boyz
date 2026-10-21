module ApplicationHelper
  MODE_LABELS = { "singles" => "1v1", "doubles" => "2v2" }.freeze

  def mode_label(mode) = MODE_LABELS.fetch(mode)

  # Which top-bar item the current page belongs to; player and team pages sit under the leaderboard.
  def nav_section
    case controller_name
    when "games" then :games
    when "plays" then :play
    when "predictions" then :predict
    else :leaderboard
    end
  end

  def rating_text(rating) = rating.round.to_s

  def delta_text(delta)
    rounded = delta.round
    rounded.positive? ? "+#{rounded}" : rounded.to_s.tr("-", "−")
  end

  def delta_class(delta)
    delta.round.negative? ? "text-rose-500" : "text-blue-600"
  end

  # Green for a win streak, red for a loss streak.
  def streak_class(streak)
    return "text-slate-400" if streak.length.zero?

    streak.won ? "text-green-600" : "text-red-500"
  end

  # Whole dollars stay whole ("$7"); anything else shows cents ("$6.50").
  def money_text(cents)
    dollars = cents.abs / 100.0
    (cents % 100).zero? ? "$#{cents.abs / 100}" : format("$%.2f", dollars)
  end

  def money_delta_text(cents)
    return money_text(0) if cents.zero?
    "#{cents.positive? ? "+" : "−"}#{money_text(cents)}"
  end

  def money_class(cents)
    return "text-slate-400" if cents.zero?
    cents.positive? ? "text-green-600" : "text-red-500"
  end

  def percent_text(fraction) = fraction ? "#{(fraction * 100).round}%" : "—"

  def names(participations)
    participations.map { |participation| participation.player.name }.to_sentence(two_words_connector: " & ")
  end

  # Inline SVG line chart (no JS or chart library) with time on the x axis. One
  # line per series; the dashed line marks the 1000 starting rating.
  def rating_chart(series, width: 360, height: 240)
    return if series.none? { |line| line.points.size > 1 }

    left, right, top, bottom = 40, 14, 12, 26
    values = series.flat_map { |line| line.points.map(&:last) }
    low = ((values.min - 10) / 25).floor * 25
    high = ((values.max + 10) / 25).ceil * 25
    times = series.flat_map { |line| line.points.map(&:first) }
    first_time = times.min
    span = [ times.max - first_time, 2.days.to_f ].max
    x = ->(time) { left + (time - first_time) * (width - left - right).fdiv(span) }
    y = ->(value) { height - bottom - (value - low) * (height - top - bottom).fdiv(high - low) }

    grid = [ low, (low + high) / 2, high ].map do |value|
      safe_join([
        tag.line(x1: left, x2: width - right, y1: y.(value), y2: y.(value), stroke: "#e2e8f0"),
        tag.text(value.round, x: left - 6, y: y.(value) + 3, "text-anchor": "end", "font-size": 11, fill: "#94a3b8")
      ])
    end
    dates = [ 0, 1, 2, 3 ].map do |tick|
      time = first_time + span * tick / 3
      anchor = { 0 => "start", 3 => "end" }.fetch(tick, "middle")
      tag.text(Time.zone.at(time).strftime("%b %-d"), x: x.(time).round(1), y: height - 7,
        "text-anchor": anchor, "font-size": 11, fill: "#94a3b8")
    end
    baseline = tag.line(x1: left, x2: width - right, y1: y.(Elo::BASE_RATING), y2: y.(Elo::BASE_RATING),
      stroke: "#94a3b8", "stroke-dasharray": "3 3") if (low..high).cover?(Elo::BASE_RATING)
    lines = series.map do |line|
      polyline = tag.polyline(points: line.points.map { |time, value| "#{x.(time).round(1)},#{y.(value).round(1)}" }.join(" "),
        fill: "none", stroke: line.color, "stroke-width": 2, "stroke-linejoin": "round", "stroke-linecap": "round")
      time, value = line.points.last
      safe_join([ polyline, tag.circle(cx: x.(time).round(1), cy: y.(value).round(1), r: 3.5, fill: line.color) do
        tag.title("#{line.name} #{value.round}")
      end ])
    end

    tag.svg(viewBox: "0 0 #{width} #{height}", class: "w-full", role: "img", "aria-label": "Rating over time") do
      safe_join([ *grid, *dates, baseline, *lines ])
    end
  end
end
