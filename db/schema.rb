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

ActiveRecord::Schema[8.1].define(version: 2026_10_21_015755) do
  create_table "games", force: :cascade do |t|
    t.integer "mode", null: false
    t.integer "side_a_score", null: false
    t.integer "side_b_score", null: false
    t.datetime "played_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "underdog_stake_cents", default: 0, null: false
    t.integer "favorite_stake_cents", default: 0, null: false
    t.string "favorite_side"
    t.index ["played_at"], name: "index_games_on_played_at"
  end

  create_table "participations", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "player_id", null: false
    t.integer "side", null: false
    t.float "rating_before", default: 1000.0, null: false
    t.float "rating_after", default: 1000.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "player_id"], name: "index_participations_on_game_id_and_player_id", unique: true
    t.index ["game_id"], name: "index_participations_on_game_id"
    t.index ["player_id"], name: "index_participations_on_player_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "from_player_id", null: false
    t.integer "to_player_id", null: false
    t.integer "cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_player_id"], name: "index_payments_on_from_player_id"
    t.index ["to_player_id"], name: "index_payments_on_to_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "name", null: false
    t.float "singles_rating", default: 1000.0, null: false
    t.float "doubles_rating", default: 1000.0, null: false
    t.integer "singles_games_count", default: 0, null: false
    t.integer "doubles_games_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_players_on_name", unique: true
  end

  add_foreign_key "participations", "games"
  add_foreign_key "participations", "players"
  add_foreign_key "payments", "players", column: "from_player_id"
  add_foreign_key "payments", "players", column: "to_player_id"
end
