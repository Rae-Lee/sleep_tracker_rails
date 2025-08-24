module Refresher
  class SleepRankingViewRefresher < Boxenn::UseCase
    def steps
      yield refresh_materialized_view

      Success()
    end

    private

    def refresh_materialized_view
      Rails.logger.info "Refreshing materialized view: track_management_followings_weekly_sleep_rankings"
      
      Scenic.database.refresh_materialized_view(:track_management_followings_weekly_sleep_rankings, concurrently: true)

      Success()
    rescue StandardError => e
      Failure(e.message)
    end
  end
end
