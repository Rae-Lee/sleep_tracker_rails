module TrackManagement
  module Repositories
    class FollowingsWeeklySleepRanking < Homebrew::Repository
      option :entity, default: -> { Entities::SleepRecord }

      def for_follower(follower_id:)
        followed_ids = Relationship::FollowRecord.where(follower_id: follower_id).pluck(:followed_id)

        TrackManagement::WeeklySleepRanking.where(followed_id: followed_ids)
      end

      def find_by_follower_id(follower_id:, page: 1, per_page: 10)
        records = for_follower(follower_id: follower_id)
        records = records.limit(per_page).offset((page - 1) * per_page)
        records.map do |record|
          entity.new(
            user_id: record.followed_id,      
            user_name: record.followed_name,
            sleep_at: record.sleep_at_utc.to_datetime,
            wake_at: record.wake_at_utc.to_datetime,
            duration: record.duration,
            sleep_timezone: record.sleep_timezone,
            wake_timezone: record.wake_timezone
          )
        end
      end

      def count_by_follower_id(follower_id:)
        for_follower(follower_id: follower_id).count
      end
    end
  end
end
