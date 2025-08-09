class CreateFollowingsWeeklySleepRankings < ActiveRecord::Migration[7.1]
  def change
    create_view :track_management_followings_weekly_sleep_rankings, materialized: true

    add_index :track_management_followings_weekly_sleep_rankings,
              %i[followed_id sleep_at_utc],
              unique: true,
              name: 'index_followings_weekly_sleep_rankings_unique'
  end
end
