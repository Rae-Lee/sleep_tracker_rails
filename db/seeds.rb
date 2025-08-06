# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
puts "\n=== Seed data creation starts! ==="

# Clear existing data in development environment
if Rails.env.development?
  TrackManagement::SleepRecord.delete_all
  Relationship::FollowRecord.delete_all
  MasterData::User.delete_all
end

# Create Users
users_data = [
  { name: 'Alice Johnson' },
  { name: 'Bob Smith' },
  { name: 'Carol Davis' },
  { name: 'David Wilson' },
  { name: 'Emma Brown' },
  { name: 'Frank Miller' },
  { name: 'Grace Lee' },
  { name: 'Henry Taylor' },
  { name: 'Ivy Chen' },
  { name: 'Jack Anderson' }
]

created_users = users_data.map do |user_attrs|
  MasterData::User.find_or_create_by!(name: user_attrs[:name])
end

# Create Follow Relationships
follow_relationships = [
  # Alice follows others
  { follower: created_users[0], followed: created_users[1] },
  { follower: created_users[0], followed: created_users[2] },
  { follower: created_users[0], followed: created_users[3] },

  # Bob follows others
  { follower: created_users[1], followed: created_users[0] },
  { follower: created_users[1], followed: created_users[4] },
  { follower: created_users[1], followed: created_users[5] },

  # Carol follows others
  { follower: created_users[2], followed: created_users[0] },
  { follower: created_users[2], followed: created_users[1] },
  { follower: created_users[2], followed: created_users[6] },

  # David follows others
  { follower: created_users[3], followed: created_users[0] },
  { follower: created_users[3], followed: created_users[7] },
  { follower: created_users[3], followed: created_users[8] },

  # Emma follows others
  { follower: created_users[4], followed: created_users[1] },
  { follower: created_users[4], followed: created_users[9] },

  # Additional mutual follows
  { follower: created_users[5], followed: created_users[1] },
  { follower: created_users[6], followed: created_users[2] }
]

follow_relationships.each do |relationship|
  Relationship::FollowRecord.find_or_create_by!(
    follower_id: relationship[:follower].id,
    followed_id: relationship[:followed].id
  )
end

# Create sleep records for the past 14 days for each user
# Define different timezones for users to simulate global usage
user_timezones = [
  'Asia/Taipei',      # Alice - UTC+8
  'America/New_York', # Bob - UTC-5/-4
  'Europe/London',    # Carol - UTC+0/+1
  'Asia/Tokyo',       # David - UTC+9
  'Australia/Sydney', # Emma - UTC+10/+11
  'America/Los_Angeles', # Frank - UTC-8/-7
  'Europe/Berlin',    # Grace - UTC+1/+2
  'Asia/Singapore',   # Henry - UTC+8
  'America/Chicago',  # Ivy - UTC-6/-5
  'Europe/Paris'      # Jack - UTC+1/+2
]

created_users.each_with_index do |user, index|
  # Base sleep/wake hours
  base_sleep_hour = 22 + (index % 4) # 22 ~ 25
  base_wake_hour  = 6 + (index % 3)  # 6 ~ 8

  sleep_tz = ActiveSupport::TimeZone[user_timezones[index % user_timezones.length]]

  (0..13).each do |days_ago|
    date = days_ago.days.ago.to_date

    # Random variations
    sleep_variation = rand(-60..60) # minutes
    wake_variation  = rand(-30..30) # minutes

    sleep_day  = base_sleep_hour >= 24 ? date + 1.day : date
    sleep_hour = base_sleep_hour % 24
    sleep_time = sleep_tz.parse("#{sleep_day} #{sleep_hour}:00") + sleep_variation.minutes

    wake_tz = if rand < 0.1
                ActiveSupport::TimeZone[user_timezones.sample]
              else
                sleep_tz
              end

    wake_time = wake_tz.parse("#{date + 1.day} #{base_wake_hour}:00") + wake_variation.minutes

    duration = (wake_time.utc - sleep_time.utc).to_i
    duration = [duration, 12 * 60 * 60].min

    TrackManagement::SleepRecord.find_or_create_by!(
      user_id: user.id,
      sleep_at: sleep_time.utc,
      wake_at: wake_time.utc,
      sleep_timezone: sleep_tz.name,
      wake_timezone: wake_tz.name,
      duration: duration
    )
  end
end

# Reset timezone to default
Time.zone = 'UTC'

# Display summary
puts "\n=== Seed Data Summary ==="
puts "Users: #{MasterData::User.count}"
puts "Follow Relationships: #{Relationship::FollowRecord.count}"
puts "Sleep Records: #{TrackManagement::SleepRecord.count}"
puts "\n=== Seed data creation completed! ==="
