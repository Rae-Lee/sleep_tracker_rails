class MasterData::User < ApplicationRecord
  self.table_name = 'master_data_users'

  has_many :sleep_records, class_name: 'TrackManagement::SleepRecord', foreign_key: 'user_id'
  has_many :followings, class_name: 'Relationship::FollowRecord', foreign_key: 'follower_id'
  has_many :followers, class_name: 'Relationship::FollowRecord', foreign_key: 'followed_id'
end
