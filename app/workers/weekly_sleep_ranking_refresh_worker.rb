class WeeklySleepRankingRefreshWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 3

  def perform
    Rails.logger.info "Starting weekly sleep ranking refresh at #{Time.current}"
    
    result = UseCases::Followings::RefreshSleepRankingView.new.call
    
    if result.success?
      Rails.logger.info "Weekly sleep ranking refresh completed successfully"
    else
      Rails.logger.error "Weekly sleep ranking refresh failed: #{result.failure}"
      raise "Weekly sleep ranking refresh failed: #{result.failure}"
    end
  end
end
