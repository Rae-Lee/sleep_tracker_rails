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

ActiveRecord::Schema[7.1].define(version: 2025_08_03_025037) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "master_data_users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "relationship_follow_records", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "followed_id"], name: "idx_on_follower_id_followed_id_5c4bac1131", unique: true
  end

  create_table "track_management_sleep_records", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "sleep_at"
    t.datetime "wake_at"
    t.integer "duration"
    t.string "sleep_timezone"
    t.string "wake_timezone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "sleep_at"], name: "index_track_management_sleep_records_on_user_id_and_sleep_at"
  end


  create_view "track_management_followings_weekly_sleep_rankings", materialized: true, sql_definition: <<-SQL
      SELECT sr.user_id AS followed_id,
      u.name AS followed_name,
      sr.sleep_at AS sleep_at_utc,
      sr.wake_at AS wake_at_utc,
      timezone((sr.sleep_timezone)::text, sr.sleep_at) AS sleep_at_local,
      timezone((sr.wake_timezone)::text, sr.wake_at) AS wake_at_local,
      sr.sleep_timezone,
      sr.wake_timezone,
      sr.duration
     FROM (track_management_sleep_records sr
       JOIN master_data_users u ON ((u.id = sr.user_id)))
    WHERE ((timezone((sr.sleep_timezone)::text, sr.sleep_at) >= (date_trunc('week'::text, timezone((sr.sleep_timezone)::text, now())) - 'P7D'::interval)) AND (timezone((sr.sleep_timezone)::text, sr.sleep_at) < date_trunc('week'::text, timezone((sr.sleep_timezone)::text, now()))) AND (sr.wake_at IS NOT NULL))
    ORDER BY sr.duration DESC;
  SQL
  add_index "track_management_followings_weekly_sleep_rankings", ["followed_id", "sleep_at_utc"], name: "index_followings_weekly_sleep_rankings_unique", unique: true

end
