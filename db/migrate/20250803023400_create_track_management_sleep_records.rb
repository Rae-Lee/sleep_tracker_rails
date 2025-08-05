class CreateTrackManagementSleepRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :track_management_sleep_records do |t|
      t.bigint :user_id
      t.datetime :sleep_at
      t.datetime :wake_at
      t.integer :duration
      t.string :sleep_timezone
      t.string :wake_timezone

      t.timestamps
    end

    add_index :track_management_sleep_records, %i[user_id sleep_at]
  end
end
