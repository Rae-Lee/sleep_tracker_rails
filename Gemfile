source 'https://rubygems.org'

ruby '3.0.0'
gem 'bootsnap', require: false
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'rails', '~> 7.1.0'
gem 'tzinfo-data', platforms: %i[mswin mswin64 mingw x64_mingw jruby]

### Data Persistence ###
# ie. DB Adapters, Cache
gem 'oj'
gem 'redis', '>= 4.0.1'
gem 'scenic', '~> 1.5.5'

### Code Organization ###
# ie. Buisness Logic Frameworks, DDD objects...
gem 'boxenn', '~> 3.0'
gem 'dry-initializer', '~> 3.0'
gem 'dry-monads'
gem 'dry-struct', '~> 1.3'
gem 'dry-validation', '~> 1.5'

### Background Processing ###
# ie. Background Jobs, Scheduling...
gem 'sidekiq', '~> 7.0.0'
gem 'sidekiq-cron', '~> 1.12'

### API Frameworks ###
# ie. API Frameworks, Serializers, Presenters...
gem 'alba'

group :development, :test do
  gem 'byebug'
  gem 'database_cleaner-active_record'
  gem 'debug', platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot', '~> 6.5.4'
  gem 'pry'
  gem 'rspec-rails', require: false
  gem 'rspec-sidekiq', require: false
  gem 'rubocop', '~> 1.79', require: false
  gem 'timecop'
  gem 'webmock'
end
