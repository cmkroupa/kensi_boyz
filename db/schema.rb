# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_22_191906) do
  create_table "games", force: :cascade do |t|
    t.integer "winner_id"
    t.integer "loser_id"
    t.integer "winner_score"
    t.integer "loser_score"
    t.datetime "played_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.integer "elo"
    t.integer "wins"
    t.integer "losses"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "team_games", force: :cascade do |t|
    t.integer "winning_team_id", null: false
    t.integer "losing_team_id", null: false
    t.integer "winner_score"
    t.integer "loser_score"
    t.datetime "played_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["losing_team_id"], name: "index_team_games_on_losing_team_id"
    t.index ["winning_team_id"], name: "index_team_games_on_winning_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.integer "player1_id", null: false
    t.integer "player2_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player1_id"], name: "index_teams_on_player1_id"
    t.index ["player2_id"], name: "index_teams_on_player2_id"
  end

  add_foreign_key "team_games", "teams", column: "losing_team_id"
  add_foreign_key "team_games", "teams", column: "winning_team_id"
  add_foreign_key "teams", "players", column: "player1_id"
  add_foreign_key "teams", "players", column: "player2_id"
end
