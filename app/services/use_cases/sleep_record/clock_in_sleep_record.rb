module UseCases
  module SleepRecord
    class ClockInSleepRecord < Boxenn::UseCase
      option :sleep_record_repo, default: -> { TrackManagement::Repositories::SleepRecord.new }
      option :cache_service_class, default: -> { Cache::SleepRecordCacheService }
      option :sleep_record_entity_class, default: -> { TrackManagement::Entities::SleepRecord }

      PAGE = 1
      PER_PAGE = 10

      def steps(params)
        user_id = params[:identity_id]

        save_sleep_record(params)
        invalidate_cache(user_id: user_id)
        result = build_result_data(user_id: user_id)
        cache_result(result)

        Success(result)
      end

      private

      def save_sleep_record(params)
        sleep_record_entity = sleep_record_entity_class.new(
          user_id: params[:identity_id],
          sleep_at: params[:sleep_at]&.to_datetime,
          wake_at: params[:wake_at]&.to_datetime,
          sleep_timezone: params[:sleep_timezone],
          wake_timezone: params[:wake_timezone]
        )

        sleep_record_repo.save(sleep_record_entity)
      end

      def invalidate_cache(user_id:)
        cache_service = cache_service_class.new(user_id: user_id, page: PAGE)
        cache_service.invalidate_cache_key
      end

      def build_result_data(user_id:)
        user_sleep_records = fetch_sleep_records(user_id: user_id, per_page: PER_PAGE)
        total_count = sleep_record_repo.count_by_user_id(user_id: user_id)

        {
          user_id: user_id,
          sleep_records: user_sleep_records,
          pagination: {
            page: PAGE,
            per_page: PER_PAGE,
            total_count: total_count
          }
        }
      end

      def cache_result(result)
        user_id = result[:user_id]
        cache_service = cache_service_class.new(user_id: user_id, page: PAGE)
        cache_page_size = cache_service_class::PAGE_SIZE

        cache_data_hash = build_cache_data(
          result: result,
          user_id: user_id,
          cache_page_size: cache_page_size
        )

        cache_service.cache_data(cache_data_hash: cache_data_hash)
      end

      def fetch_sleep_records(user_id:, per_page:)
        sleep_record_repo.find_by_user_id(
          user_id: user_id,
          page: PAGE,
          per_page: per_page
        )
      end

      def build_cache_data(result:, user_id:, cache_page_size:)
        sleep_records = 
          if PER_PAGE == cache_page_size
            result[:sleep_records]
          else
            build_cache_data_with_different_page_size(user_id: user_id, cache_page_size: cache_page_size)
          end

        {
          sleep_records: sleep_records.map(&:to_h),
          total_count: result[:pagination][:total_count]
        }
      end

      def build_cache_data_with_different_page_size(user_id:, cache_page_size:)
        fetch_sleep_records(user_id: user_id, per_page: cache_page_size)
      end
    end
  end
end
