module ChartHelper
  # Inline SVG bar chart (no JS or library). Labels are sparse: pass { index => text }
  # for the bars that should be named underneath.
  def bar_chart(values, labels: {}, width: 360, height: 150, label: "Chart")
    return if values.none?(&:positive?)

    left, right, top, bottom = 24, 4, 12, 22
    peak = values.max
    slot = (width - left - right).fdiv(values.size)
    scale = (height - top - bottom).fdiv(peak)

    bars = values.each_with_index.map do |value, index|
      bar_height = value * scale
      tag.rect(x: (left + slot * index + slot * 0.12).round(1), y: (height - bottom - bar_height).round(1),
        width: (slot * 0.76).round(1), height: bar_height.round(1), rx: 2, fill: "#2563eb") do
        tag.title(value)
      end
    end
    names = labels.map do |index, text|
      tag.text(text, x: (left + slot * index + slot / 2).round(1), y: height - 6, "text-anchor": "middle", "font-size": 11, fill: "#94a3b8")
    end

    tag.svg(viewBox: "0 0 #{width} #{height}", class: "w-full", role: "img", "aria-label": label) do
      safe_join([
        tag.line(x1: left, x2: width - right, y1: height - bottom, y2: height - bottom, stroke: "#e2e8f0"),
        tag.text(peak, x: left - 6, y: top + 4, "text-anchor": "end", "font-size": 11, fill: "#94a3b8"),
        *bars, *names
      ])
    end
  end

  def hour_text(hour)
    suffix = hour < 12 ? "am" : "pm"
    "#{hour % 12 == 0 ? 12 : hour % 12}#{suffix}"
  end
end
