class TrackManagement::WeeklySleepRanking < ApplicationRecord
  self.primary_key = nil
  self.table_name = 'track_management_followings_weekly_sleep_rankings'

  def readonly?
    true
  end
end
