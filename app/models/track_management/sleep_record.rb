class TrackManagement::SleepRecord < ApplicationRecord
  self.table_name = 'track_management_sleep_records'

  belongs_to :user, class_name: 'MasterData::User'
end
