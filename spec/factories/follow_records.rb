FactoryBot.define do
  factory :follow_record, class: 'Relationship::FollowRecord' do
    association :follower, factory: :user
    association :followed, factory: :user
    
    trait :with_sleep_data do
      after(:create) do |follow_record|
        # Create sleep records for the followed user
        create_list(:sleep_record, 3, user: follow_record.followed)
      end
    end
  end
end