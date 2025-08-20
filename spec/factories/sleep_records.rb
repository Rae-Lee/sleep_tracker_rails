FactoryBot.define do
  factory :sleep_record, class: 'TrackManagement::SleepRecord' do
    association :user, factory: :user
    sleep_at { 2.days.ago.beginning_of_day + 22.hours }
    wake_at { 1.day.ago.beginning_of_day + 6.hours }
    sleep_timezone { 'UTC' }
    wake_timezone { 'UTC' }
    duration { (wake_at - sleep_at).to_i }
    
    trait :incomplete do
      wake_at { nil }
      wake_timezone { nil }
      duration { nil }
    end
    
    trait :long_sleep do
      sleep_at { 2.days.ago.beginning_of_day + 21.hours }
      wake_at { 1.day.ago.beginning_of_day + 8.hours }
      duration { (wake_at - sleep_at).to_i }
    end
    
    trait :short_sleep do
      sleep_at { 2.days.ago.beginning_of_day + 23.hours }
      wake_at { 1.day.ago.beginning_of_day + 5.hours }
      duration { (wake_at - sleep_at).to_i }
    end
    
    trait :previous_week do
      sleep_at do
        # Calculate previous week's Monday in the specified timezone
        previous_week_start = Time.current.in_time_zone('Asia/Taipei').beginning_of_week(:monday) - 1.week
        previous_week_start + 22.hours # Sleep at 10 PM on Monday of previous week
      end
      
      wake_at do
        sleep_at + 8.hours # Wake up after 8 hours of sleep
      end
      
      sleep_timezone { 'Asia/Taipei' }
      wake_timezone { 'Asia/Taipei' }
      duration { (wake_at - sleep_at).to_i }
    end
  end
end