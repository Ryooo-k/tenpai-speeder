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

ActiveRecord::Schema[8.0].define(version: 2025_07_16_211147) do
  create_table "actions", force: :cascade do |t|
    t.integer "step_id", null: false
    t.integer "player_id", null: false
    t.integer "from_player_id"
    t.integer "action_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_player_id"], name: "index_actions_on_from_player_id"
    t.index ["player_id"], name: "index_actions_on_player_id"
    t.index ["step_id"], name: "index_actions_on_step_id"
  end

  create_table "ais", force: :cascade do |t|
    t.string "name", null: false
    t.string "version", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "base_tiles", force: :cascade do |t|
    t.integer "suit", null: false
    t.integer "number", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_favorites_on_game_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "game_modes", force: :cascade do |t|
    t.integer "mode_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "games", force: :cascade do |t|
    t.integer "game_mode_id", null: false
    t.integer "rule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_mode_id"], name: "index_games_on_game_mode_id"
    t.index ["rule_id"], name: "index_games_on_rule_id"
  end

  create_table "hands", force: :cascade do |t|
    t.integer "player_state_id", null: false
    t.integer "tile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_state_id"], name: "index_hands_on_player_state_id"
    t.index ["tile_id"], name: "index_hands_on_tile_id"
  end

  create_table "honbas", force: :cascade do |t|
    t.integer "round_id", null: false
    t.integer "number", default: 0, null: false
    t.integer "riichi_stick_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["round_id"], name: "index_honbas_on_round_id"
  end

  create_table "melds", force: :cascade do |t|
    t.integer "player_state_id", null: false
    t.integer "tile_id", null: false
    t.integer "action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_id"], name: "index_melds_on_action_id"
    t.index ["player_state_id"], name: "index_melds_on_player_state_id"
    t.index ["tile_id"], name: "index_melds_on_tile_id"
  end

  create_table "player_states", force: :cascade do |t|
    t.integer "step_id", null: false
    t.integer "player_id", null: false
    t.boolean "riichi", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_player_states_on_player_id"
    t.index ["step_id"], name: "index_player_states_on_step_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "user_id"
    t.integer "ai_id"
    t.integer "game_id", null: false
    t.integer "seat_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_id"], name: "index_players_on_ai_id"
    t.index ["game_id"], name: "index_players_on_game_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "results", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "player_id", null: false
    t.integer "score", null: false
    t.integer "rank", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_results_on_game_id"
    t.index ["player_id"], name: "index_results_on_player_id"
  end

  create_table "rivers", force: :cascade do |t|
    t.integer "player_state_id", null: false
    t.integer "tile_id", null: false
    t.boolean "tsumogiri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_state_id"], name: "index_rivers_on_player_state_id"
    t.index ["tile_id"], name: "index_rivers_on_tile_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "number", null: false
    t.integer "host_position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_rounds_on_game_id"
  end

  create_table "rules", force: :cascade do |t|
    t.boolean "aka_dora", default: true, null: false
    t.integer "round_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scores", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "honba_id", null: false
    t.integer "score", null: false
    t.integer "point"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["honba_id"], name: "index_scores_on_honba_id"
    t.index ["player_id"], name: "index_scores_on_player_id"
  end

  create_table "steps", force: :cascade do |t|
    t.integer "turn_id", null: false
    t.integer "number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["turn_id"], name: "index_steps_on_turn_id"
  end

  create_table "tile_orders", force: :cascade do |t|
    t.integer "tile_id", null: false
    t.integer "honba_id", null: false
    t.integer "order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["honba_id"], name: "index_tile_orders_on_honba_id"
    t.index ["tile_id"], name: "index_tile_orders_on_tile_id"
  end

  create_table "tiles", force: :cascade do |t|
    t.integer "base_tile_id", null: false
    t.integer "game_id", null: false
    t.integer "code", null: false
    t.boolean "aka", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_tile_id"], name: "index_tiles_on_base_tile_id"
    t.index ["game_id"], name: "index_tiles_on_game_id"
  end

  create_table "turns", force: :cascade do |t|
    t.integer "honba_id", null: false
    t.integer "number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["honba_id"], name: "index_turns_on_honba_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "provider"
    t.string "uid"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "actions", "players"
  add_foreign_key "actions", "players", column: "from_player_id"
  add_foreign_key "actions", "steps"
  add_foreign_key "favorites", "games"
  add_foreign_key "favorites", "users"
  add_foreign_key "games", "game_modes"
  add_foreign_key "games", "rules"
  add_foreign_key "hands", "player_states"
  add_foreign_key "hands", "tiles"
  add_foreign_key "honbas", "rounds"
  add_foreign_key "melds", "actions"
  add_foreign_key "melds", "player_states"
  add_foreign_key "melds", "tiles"
  add_foreign_key "player_states", "players"
  add_foreign_key "player_states", "steps"
  add_foreign_key "players", "ais"
  add_foreign_key "players", "games"
  add_foreign_key "players", "users"
  add_foreign_key "results", "games"
  add_foreign_key "results", "players"
  add_foreign_key "rivers", "player_states"
  add_foreign_key "rivers", "tiles"
  add_foreign_key "rounds", "games"
  add_foreign_key "scores", "honbas"
  add_foreign_key "scores", "players"
  add_foreign_key "steps", "turns"
  add_foreign_key "tile_orders", "honbas"
  add_foreign_key "tile_orders", "tiles"
  add_foreign_key "tiles", "base_tiles"
  add_foreign_key "tiles", "games"
  add_foreign_key "turns", "honbas"
end
