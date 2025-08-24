require 'rails_helper'

RSpec.describe Refresher::SleepRankingViewRefresher do
  subject { described_class.new }

  before do
    allow(Scenic.database).to receive(:refresh_materialized_view)
  end

  describe '#call' do
    it 'refreshes materialized view successfully' do
      result = subject.call

      expect(result).to be_success
      expect(Scenic.database).to have_received(:refresh_materialized_view)
        .with(:track_management_followings_weekly_sleep_rankings, concurrently: true)
    end

    context 'when an error occurs' do
      before do
        allow(Scenic.database).to receive(:refresh_materialized_view).and_raise(StandardError, 'Database error')
      end

      it 'returns failure result' do
        result = subject.call

        expect(result).to be_failure
      end
    end
  end
end
