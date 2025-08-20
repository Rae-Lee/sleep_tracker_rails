class Cache::SleepRecordCacheService < Redis::BaseCacheAdapter
  option :page, default: -> { 1 }
  
  CACHE_EXPIRY = 1.hour.freeze
  CACHE_KEY_PREFIX = 'sleep_records'.freeze
  PAGE_SIZE = 10

  private

  def cache_key
    build_base_cache_key(suffix: "page:#{page}")
  end

  def cache_key_prefix
    CACHE_KEY_PREFIX
  end

  def cache_expiry
    CACHE_EXPIRY
  end
end
