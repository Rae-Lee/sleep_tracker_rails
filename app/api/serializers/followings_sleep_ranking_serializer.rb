class Serializers::FollowingsSleepRankingSerializer
  include Alba::Resource

  attributes :sleep_timezone, :wake_timezone, :duration

  attribute :followed_id do |object|
    object.user_id
  end

  attribute :followed_name do |object|
    object.user_name
  end

  attribute :sleep_at do |object|
    object.sleep_at&.iso8601
  end

  attribute :wake_at do |object|
    object.wake_at&.iso8601
  end

  attribute :sleep_at_in_timezone do |object|
    object.sleep_at_in_timezone&.iso8601
  end

  attribute :wake_at_in_timezone do |object|
    object.wake_at_in_timezone&.iso8601
  end
end
