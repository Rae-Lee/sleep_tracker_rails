class Redis::BaseCacheAdapter
  extend Dry::Initializer

  option :user_id
  option :redis, default: -> { $redis }

  def get_cached_data
    cached_data = redis.get(cache_key)
    return nil unless cached_data

    JSON.parse(cached_data, symbolize_names: true)
  rescue JSON::ParserError
    nil
  end

  def cache_data(cache_data_hash:)
    redis.setex(cache_key, cache_expiry.to_i, cache_data_hash.to_json)
  end

  def cache_exists?
    redis.exists?(cache_key) == true
  end

  def invalidate_cache_key
    redis.del(cache_key)
  end

  def invalidate_all_user_cache
    pattern = "#{cache_key_prefix}:user:#{user_id}:*"
    keys = redis.keys(pattern)
    redis.del(*keys) if keys.any?
  end

  private

  def build_base_cache_key(suffix:)
    "#{cache_key_prefix}:user:#{user_id}:#{suffix}"
  end

  def cache_key_prefix
    raise NotImplementedError, 'Subclasses must implement cache_key_prefix'
  end

  def cache_expiry
    raise NotImplementedError, 'Subclasses must implement cache_expiry'
  end

  def cache_key
    raise NotImplementedError, 'Subclasses must implement cache_key'
  end
end
