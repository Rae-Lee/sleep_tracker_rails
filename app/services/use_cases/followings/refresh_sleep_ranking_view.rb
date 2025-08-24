module UseCases
  module Followings
    class RefreshSleepRankingView < Boxenn::UseCase
      option :refresher_service, default: -> { Refresher::SleepRankingViewRefresher.new }
      option :cache_service_class, default: -> { Cache::FollowingsSleepRecordsCacheService }
      option :get_sleep_ranking_use_case, default: -> { UseCases::Followings::GetSleepRanking.new }
      option :user_repo, default: -> { MasterData::Repositories::User.new }
      
      def steps
        yield call_refresher_service
        invalidate_cache
        yield refresh_heavy_users_cache
        reset_query_counters
        
        Success()
      end

      private

      def call_refresher_service
        result = refresher_service.call   
        return Failure(result.failure) if result.failure?
        
        Success()
      end

      def invalidate_cache
        Rails.logger.info "Invalidating users cache"
        
        cache_service.invalidate_all_followings_cache
      end

      def refresh_heavy_users_cache
        Rails.logger.info "Refreshing heavy users cache with new data"

        user_repo.all_user_ids.each do |user_id|
          params = { identity_id: user_id, page: 1, per_page: cache_service_class::PAGE_SIZE }
          result = get_sleep_ranking_use_case.call(params)          
          
          return Failure("Failed to refresh cache for user #{user_id}: #{result.failure}") if result.failure?
        end

        Success()
      end

      def reset_query_counters
        Rails.logger.info "Resetting query counters"
        
        cache_service.invalidate_all_query_counters
      end

      def cache_service
        @cache_service ||= cache_service_class.new(user_id: 1)
      end
    end
  end
end
