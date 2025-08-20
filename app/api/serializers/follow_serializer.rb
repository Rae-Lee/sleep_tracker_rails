class Serializers::FollowSerializer
  include Alba::Resource

  attribute :user_id do |record|
    record.follower_id
  end

  attribute :data do |record|
    {
      followed_id: record.followed_id,
      followed_name: record.followed&.name
    }
  end

  attribute :created_at do |record|
    record.created_at&.iso8601
  end
end
