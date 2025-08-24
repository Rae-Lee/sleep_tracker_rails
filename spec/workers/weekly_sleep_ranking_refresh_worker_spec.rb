require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe WeeklySleepRankingRefreshWorker, type: :worker do
  describe '.perform_async' do
    it 'enqueues a job' do
      expect {
        WeeklySleepRankingRefreshWorker.perform_async
      }.to change(WeeklySleepRankingRefreshWorker.jobs, :size).by(1)
    end
  end
end
