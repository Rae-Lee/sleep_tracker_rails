class Serializers::SleepRecordsSerializer
  include Alba::Resource

  attributes :sleep_timezone, :wake_timezone, :duration

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

  attribute :created_at do |object|
    object.created_at&.iso8601
  end

  attribute :status do |object|
    object.incomplete? ? 'sleeping' : 'completed'
  end
end
