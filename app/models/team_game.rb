class TeamGame < ApplicationRecord
  belongs_to :winning_team, class_name: "Team"
  belongs_to :losing_team, class_name: "Team"
end
