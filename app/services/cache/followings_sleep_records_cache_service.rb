class Cache::FollowingsSleepRecordsCacheService < Redis::BaseCacheAdapter
  option :page, default: -> { 1 }
  option :sleep_record_entity, default: -> { TrackManagement::Entities::SleepRecord }

  CACHE_EXPIRY = 8.days.freeze
  CACHE_KEY_PREFIX = 'followings_sleep_records'.freeze
  QUERY_COUNTER_PREFIX = 'followings_query_count'.freeze
  HEAVY_USER_THRESHOLD = 20
  PAGE_SIZE = 10

  def fetch_cached_entities
    data = get_cached_data
    ranking_entities = data[:rankings].map do |item|
      sleep_record_entity.new(
        user_id: item[:user_id],
        user_name: item[:user_name],
        sleep_at: item[:sleep_at].to_datetime,
        wake_at: item[:wake_at].to_datetime,
        duration: item[:duration],
        sleep_timezone: item[:sleep_timezone],
        wake_timezone: item[:wake_timezone],
      )
    end
   

    {
      rankings: ranking_entities,
      total_count: data[:total_count],
    }
  end

  def increment_query_count
    counter_key = build_query_counter_key
    redis.incr(counter_key)

    redis.expire(counter_key, cache_expiry.to_i)
  end

  def get_query_count
    counter_key = build_query_counter_key
    (redis.get(counter_key) || 0).to_i
  end

  def is_heavy_user?
    get_query_count >= HEAVY_USER_THRESHOLD
  end

  def should_cache?
    is_heavy_user? && !cache_exists? && page == 1
  end

  def reset_query_counter
    counter_key = build_query_counter_key
    invalidate_cache_key(counter_key)
  end

  private

  def cache_key
    week_key = last_week_key
    build_base_cache_key(suffix: "#{week_key}:page:#{page}")
  end

  def build_query_counter_key
    week_key = last_week_key
    "#{QUERY_COUNTER_PREFIX}:user:#{user_id}:#{week_key}"
  end

  def last_week_key
    (Time.current - 1.week).beginning_of_week(:monday).strftime('%Y-W%U')
  end

  def cache_key_prefix
    CACHE_KEY_PREFIX
  end

  def cache_expiry
    CACHE_EXPIRY
  end
end
