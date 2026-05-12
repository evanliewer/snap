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

ActiveRecord::Schema[8.1].define(version: 2026_05_12_225308) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "submission_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["submission_id"], name: "index_comments_on_submission_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.boolean "allow_video", default: false, null: false
    t.boolean "auto_approve", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "join_code", null: false
    t.bigint "owner_id", null: false
    t.boolean "show_leaderboard", default: true, null: false
    t.datetime "starts_at"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["join_code"], name: "index_games_on_join_code", unique: true
    t.index ["owner_id"], name: "index_games_on_owner_id"
    t.index ["status"], name: "index_games_on_status"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.string "role", default: "player", null: false
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id"], name: "index_memberships_on_game_id"
    t.index ["team_id"], name: "index_memberships_on_team_id"
    t.index ["user_id", "game_id"], name: "index_memberships_on_user_id_and_game_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "mission_categories", force: :cascade do |t|
    t.string "color", default: "#10B981", null: false
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "position"], name: "index_mission_categories_on_game_id_and_position"
    t.index ["game_id"], name: "index_mission_categories_on_game_id"
  end

  create_table "missions", force: :cascade do |t|
    t.datetime "available_from"
    t.datetime "available_until"
    t.integer "bonus_points", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "first_bonus_count", default: 0, null: false
    t.integer "first_bonus_points", default: 0, null: false
    t.bigint "game_id", null: false
    t.decimal "hotspot_latitude", precision: 10, scale: 6
    t.decimal "hotspot_longitude", precision: 10, scale: 6
    t.integer "hotspot_radius_m"
    t.integer "max_submissions_per_team", default: 1, null: false
    t.bigint "mission_category_id"
    t.string "mission_type", default: "photo", null: false
    t.integer "points", default: 100, null: false
    t.integer "position", default: 0, null: false
    t.boolean "repeatable", default: false, null: false
    t.boolean "required", default: false, null: false
    t.boolean "requires_location", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "position"], name: "index_missions_on_game_id_and_position"
    t.index ["game_id"], name: "index_missions_on_game_id"
    t.index ["mission_category_id"], name: "index_missions_on_mission_category_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind"
    t.bigint "submission_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["submission_id"], name: "index_reactions_on_submission_id"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.text "caption"
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.bigint "mission_id", null: false
    t.integer "points_awarded", default: 0, null: false
    t.text "review_notes"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.string "status", default: "approved", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_submissions_on_created_at"
    t.index ["mission_id", "team_id"], name: "index_submissions_on_mission_id_and_team_id"
    t.index ["mission_id"], name: "index_submissions_on_mission_id"
    t.index ["reviewed_by_id"], name: "index_submissions_on_reviewed_by_id"
    t.index ["status"], name: "index_submissions_on_status"
    t.index ["team_id"], name: "index_submissions_on_team_id"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "color", default: "#4F46E5", null: false
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "name"], name: "index_teams_on_game_id_and_name", unique: true
    t.index ["game_id"], name: "index_teams_on_game_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "submissions"
  add_foreign_key "comments", "users"
  add_foreign_key "games", "users", column: "owner_id"
  add_foreign_key "memberships", "games"
  add_foreign_key "memberships", "teams"
  add_foreign_key "memberships", "users"
  add_foreign_key "mission_categories", "games"
  add_foreign_key "missions", "games"
  add_foreign_key "missions", "mission_categories"
  add_foreign_key "reactions", "submissions"
  add_foreign_key "reactions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "submissions", "missions"
  add_foreign_key "submissions", "teams"
  add_foreign_key "submissions", "users"
  add_foreign_key "submissions", "users", column: "reviewed_by_id"
  add_foreign_key "teams", "games"
end
