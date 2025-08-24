FactoryBot.define do
  factory :track_management_entities_sleep_record, class: 'TrackManagement::Entities::SleepRecord' do
    user_id { 1 }
    user_name { 'John Doe' }
    sleep_at { (2.days.ago.beginning_of_day + 22.hours).iso8601 }
    wake_at { (1.day.ago.beginning_of_day + 6.hours).iso8601 }
    duration { ((1.day.ago.beginning_of_day + 6.hours) - (2.days.ago.beginning_of_day + 22.hours)).to_i }
    sleep_timezone { 'UTC' }
    wake_timezone { 'UTC' }
    created_at { 2.days.ago.iso8601 }
    
    skip_create
    initialize_with { new(attributes) }
    
    trait :incomplete do
      wake_at { nil }
      wake_timezone { nil }
      duration { nil }
    end
    
    trait :long_sleep do
      sleep_at { (2.days.ago.beginning_of_day + 21.hours).iso8601 }
      wake_at { (1.day.ago.beginning_of_day + 8.hours).iso8601 }
      duration { ((1.day.ago.beginning_of_day + 8.hours) - (2.days.ago.beginning_of_day + 21.hours)).to_i }
    end
    
    trait :short_sleep do
      sleep_at { (2.days.ago.beginning_of_day + 23.hours).iso8601 }
      wake_at { (1.day.ago.beginning_of_day + 5.hours).iso8601 }
      duration { ((1.day.ago.beginning_of_day + 5.hours) - (2.days.ago.beginning_of_day + 23.hours)).to_i }
    end
    
    trait :with_timezone do
      sleep_timezone { 'Asia/Taipei' }
      wake_timezone { 'Asia/Taipei' }
      sleep_at do
        (Time.current.in_time_zone('Asia/Taipei').beginning_of_day + 22.hours - 2.days).iso8601
      end
      wake_at do
        sleep_time = Time.current.in_time_zone('Asia/Taipei').beginning_of_day + 22.hours - 2.days
        (sleep_time + 8.hours).iso8601
      end
      duration do
        sleep_time = Time.current.in_time_zone('Asia/Taipei').beginning_of_day + 22.hours - 2.days
        wake_time = sleep_time + 8.hours
        (wake_time - sleep_time).to_i
      end
    end
    
    trait :previous_week do
      sleep_at do
        previous_week_start = Time.current.in_time_zone('Asia/Taipei').beginning_of_week(:monday) - 1.week
        (previous_week_start + 22.hours).iso8601
      end
      
      wake_at do
        previous_week_start = Time.current.in_time_zone('Asia/Taipei').beginning_of_week(:monday) - 1.week
        sleep_time = previous_week_start + 22.hours
        (sleep_time + 8.hours).iso8601
      end
      
      sleep_timezone { 'Asia/Taipei' }
      wake_timezone { 'Asia/Taipei' }
      duration do
        previous_week_start = Time.current.in_time_zone('Asia/Taipei').beginning_of_week(:monday) - 1.week
        sleep_time = previous_week_start + 22.hours
        wake_time = sleep_time + 8.hours
        (wake_time - sleep_time).to_i
      end
    end
  end
end