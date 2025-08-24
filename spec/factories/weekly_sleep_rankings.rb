FactoryBot.define do
  factory :weekly_sleep_ranking, class: 'TrackManagement::WeeklySleepRanking' do
    # Note: This is a read-only view, so we'll create the underlying data
    # and let the view populate itself
    
    trait :with_ranking_data do
      transient do
        follower { create(:user) }
        followed_users { create_list(:user, 3) }
      end
      
      after(:build) do |ranking, evaluator|
        # Create follow relationships
        evaluator.followed_users.each do |followed_user|
          create(:follow_record, follower: evaluator.follower, followed: followed_user)
        end
        
        # Create sleep records for followed users with different durations
        evaluator.followed_users.each_with_index do |followed_user, index|
          duration_hours = [8, 7, 6][index] || 8
          sleep_time = 1.week.ago.beginning_of_week(:monday) + 22.hours
          wake_time = sleep_time + duration_hours.hours
          
          create(:sleep_record, 
            user: followed_user,
            sleep_at: sleep_time,
            wake_at: wake_time,
            duration: duration_hours * 3600
          )
        end
      end
    end
  end
end