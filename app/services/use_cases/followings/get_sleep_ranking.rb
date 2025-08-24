module UseCases
  module Followings
    class GetSleepRanking < Boxenn::UseCase
      option :rankings_repo, default: -> { TrackManagement::Repositories::FollowingsWeeklySleepRanking.new }
      option :cache_service_class, default: -> { Cache::FollowingsSleepRecordsCacheService }

      def steps(params)
        user_id = params[:identity_id]
        page = params[:page] || 1
        per_page = params[:per_page] || 10
        cache_service = build_cache_service(user_id: user_id, page: page)
        
        increment_query_count(cache_service)
        result = build_result_data(cache_service: cache_service, user_id: user_id, page: page, per_page: per_page)
        cache_result_if_needed(cache_service: cache_service, result: result)

        Success(result)
      end

      private

      def build_cache_service(user_id:, page:)
        cache_service_class.new(user_id: user_id, page: page)
      end

      def increment_query_count(cache_service)
        cache_service.increment_query_count
      end

      def build_result_data(cache_service:, user_id:, page:, per_page:)
        week_dates = calculate_previous_week_dates
        result =
            if cache_service.cache_exists? && per_page == cache_service_class::PAGE_SIZE
              cache_service.fetch_cached_entities
            else
              build_fresh_result(user_id: user_id, page: page, per_page: per_page, cache_service: cache_service)
            end
        {
          user_id: user_id,
          week_start: week_dates[:start].strftime('%Y-%m-%d'),
          week_end: week_dates[:end].strftime('%Y-%m-%d'),
          rankings: result[:rankings],
          pagination: build_pagination_data(page: page, per_page: per_page, total_count: result[:total_count])
        }
      end

      def build_fresh_result(user_id:, page:, per_page:, cache_service:)
        rankings = fetch_rankings(user_id: user_id, page: page, per_page: per_page)
        total_count = rankings_repo.count_by_follower_id(follower_id: user_id)
        
        {
            rankings: rankings,
            total_count: total_count,
        }
      end

      def fetch_rankings(user_id:, page:, per_page:)
        rankings_repo.find_by_follower_id(
          follower_id: user_id,
          page: page,
          per_page: per_page
        )
      end

      def calculate_previous_week_dates
        {
          start: 1.week.ago.beginning_of_week(:monday),
          end: 1.week.ago.end_of_week(:sunday)
        }
      end

      def build_pagination_data(page:, per_page:, total_count:)
        {
          page: page,
          per_page: per_page,
          total_count: total_count
        }
      end

      def cache_result_if_needed(cache_service:, result:)
        if cache_service.should_cache?
          cache_page_size = cache_service_class::PAGE_SIZE
          cache_data_hash = build_cache_data(
            result: result,
            cache_page_size: cache_page_size,
          )
          cache_service.cache_data(cache_data_hash: cache_data_hash)
        end
      end

       def build_cache_data(result:, cache_page_size:)
        rankings =
          if result[:pagination][:per_page] == cache_page_size
            result[:rankings]
          else
            build_cache_data_with_different_page_size(result: result, cache_page_size: cache_page_size)
          end

        {
          rankings: rankings.map(&:to_h),
          total_count: result[:pagination][:total_count]
        }
      end

       def build_cache_data_with_different_page_size(result:, cache_page_size:)
        fetch_rankings(user_id: result[:user_id], per_page: cache_page_size, page: result[:pagination][:page])
      end
    end
  end
end
