FactoryBot.define do
  factory :user, class: 'MasterData::User' do
    sequence(:id) { |n| n }
    
    trait :with_sleep_records do
      after(:create) do |user|
        create_list(:sleep_record, 3, user: user)
      end
    end
    
    trait :with_followings do
      after(:create) do |user|
        followed_users = create_list(:user, 2)
        followed_users.each do |followed_user|
          create(:follow_record, follower: user, followed: followed_user)
        end
      end
    end
  end
end