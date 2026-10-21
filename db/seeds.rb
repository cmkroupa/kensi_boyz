%w[ Cameron Quinn Tyler Evan Angelo Nash ].each do |name|
  Player.find_or_create_by!(name: name)
end

load Rails.root.join("db/seeds/demo.rb") if ENV["DEMO_DATA"].present?
