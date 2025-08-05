class Relationship::FollowRecord < ApplicationRecord
  self.table_name = 'relationship_follow_records'

  belongs_to :follower, class_name: 'MasterData::User'
  belongs_to :followed, class_name: 'MasterData::User'
end
