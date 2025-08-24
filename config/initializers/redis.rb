require 'redis'

begin
  $redis = Redis.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    timeout: 30
  )
  puts "Redis connection established: #{$redis.ping}" # => PONG
rescue StandardError => e
  $redis = nil
  warn "Warning: No Redis server! Error: #{e.message}"
end
