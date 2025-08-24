# Weekly Sleep Ranking Refresh

This document describes the weekly sleep ranking refresh functionality that automatically updates the materialized view and refreshes cache for heavy users.

## Overview

The system automatically refreshes the `track_management_followings_weekly_sleep_rankings` materialized view every Monday at 1:00 AM and updates the Redis cache for heavy users.

## Components

### 1. Sidekiq Worker
- **File**: `app/workers/weekly_sleep_ranking_refresh_worker.rb`
- **Schedule**: Every Monday at 1:00 AM (cron: `0 1 * * 1`)
- **Purpose**: Triggers the weekly refresh process

### 2. Refresher Service
- **File**: `app/services/refresher/sleep_ranking_view_refresher.rb`
- **Purpose**: Handles the materialized view refresh only

### 3. Use Case
- **File**: `app/services/use_cases/followings/refresh_sleep_ranking_view.rb`
- **Purpose**: Orchestrates the complete refresh process including:
  - Calling the refresher service to refresh the materialized view
  - Identifying heavy users (users with ≥20 queries)
  - Invalidating heavy users' cache
  - Refreshing heavy users' cache with new data
  - Resetting query counters

### 4. Configuration Files
- **Sidekiq Config**: `config/initializers/sidekiq.rb`
- **Cron Schedule**: `config/schedule.yml`

## How It Works

1. **Scheduled Execution**: Every Monday at 1:00 AM, Sidekiq executes `WeeklySleepRankingRefreshWorker`

2. **Materialized View Refresh**: The worker calls the use case which refreshes the `track_management_followings_weekly_sleep_rankings` materialized view using Scenic

3. **Heavy User Identification**: The system identifies heavy users by scanning Redis for query counters that exceed the threshold (20 queries)

4. **Cache Management**: For each heavy user:
   - Invalidates all existing cache entries
   - Calls the `GetSleepRanking` use case to refresh cache with new data
   - Resets the query counter

## Manual Execution

You can manually trigger the refresh process:

```ruby
# Execute the worker directly
WeeklySleepRankingRefreshWorker.perform_async

# Or call the use case directly
UseCases::Followings::RefreshSleepRankingView.new.call

# Or call the refresher service directly
Refresher::SleepRankingViewRefresher.new.call
```

## Monitoring

The system logs important events:
- Start and completion of refresh process
- Heavy user identification
- Cache invalidation and refresh for each user
- Any errors that occur during the process

## Configuration

### Heavy User Threshold
The heavy user threshold is defined in `Cache::FollowingsSleepRecordsCacheService::HEAVY_USER_THRESHOLD` (default: 20 queries).

### Schedule
The cron schedule is defined in `config/schedule.yml` and can be modified as needed.

## Dependencies

- **Sidekiq**: Background job processing
- **sidekiq-cron**: Cron-style scheduling
- **Redis**: Cache storage and query counting
- **Scenic**: Materialized view management