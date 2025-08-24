require 'rails_helper'

RSpec.describe UseCases::Followings::RefreshSleepRankingView do
  subject { described_class.new(user_repo: user_repo_double) }

  let(:refresher_double) { instance_double(Refresher::SleepRankingViewRefresher) }
  let(:user_repo_double) { instance_double(MasterData::Repositories::User) }
  let(:use_case_double) { instance_double(UseCases::Followings::GetSleepRanking) }
  let(:success_result) { double('result', success?: true, failure?: false) }
  let(:cache_service) { instance_double(Cache::FollowingsSleepRecordsCacheService) }

  before do
    allow(Refresher::SleepRankingViewRefresher).to receive(:new).and_return(refresher_double)
    allow(refresher_double).to receive(:call).and_return(success_result)
    allow(Cache::FollowingsSleepRecordsCacheService).to receive(:new).and_return(cache_service)
    allow(cache_service).to receive(:invalidate_all_followings_cache)
    allow(cache_service).to receive(:invalidate_all_query_counters)
    allow(UseCases::Followings::GetSleepRanking).to receive(:new).and_return(use_case_double)
    allow(use_case_double).to receive(:call).and_return(success_result)
  end

  describe '#call' do
    context 'when no users exist' do
      before do
        allow(user_repo_double).to receive(:all_user_ids).and_return([])
      end

      it 'calls refresher service and invalidates cache successfully' do
        result = subject.call

        expect(result).to be_success
        expect(Refresher::SleepRankingViewRefresher).to have_received(:new)
        expect(refresher_double).to have_received(:call)
        expect(cache_service).to have_received(:invalidate_all_followings_cache)
        expect(cache_service).to have_received(:invalidate_all_query_counters)
      end
    end

    context 'when users exist' do
      let(:user_ids) { [123, 456, 789] }

      before do
        allow(user_repo_double).to receive(:all_user_ids).and_return(user_ids)
      end

      it 'processes all users and refreshes their cache' do
        result = subject.call

        expect(result).to be_success
        expect(refresher_double).to have_received(:call)
        expect(cache_service).to have_received(:invalidate_all_followings_cache)
        expect(cache_service).to have_received(:invalidate_all_query_counters)
        expect(use_case_double).to have_received(:call).with(
          { identity_id: 123, page: 1, per_page: Cache::FollowingsSleepRecordsCacheService::PAGE_SIZE }
        )
        expect(use_case_double).to have_received(:call).with(
          { identity_id: 456, page: 1, per_page: Cache::FollowingsSleepRecordsCacheService::PAGE_SIZE }
        )
        expect(use_case_double).to have_received(:call).with(
          { identity_id: 789, page: 1, per_page: Cache::FollowingsSleepRecordsCacheService::PAGE_SIZE }
        )
      end
    end

    context 'when refresher service fails' do
      let(:failure_result) { double('result', success?: false, failure?: true, failure: 'Database error') }

      before do
        allow(refresher_double).to receive(:call).and_return(failure_result)
        allow(user_repo_double).to receive(:all_user_ids).and_return([])
      end

      it 'returns failure result' do
        result = subject.call

        expect(result).to be_failure
      end
    end

    context 'when get sleep ranking use case fails' do
      let(:failure_result) { double('result', success?: false, failure?: true, failure: 'Ranking error') }

      before do
        allow(user_repo_double).to receive(:all_user_ids).and_return([123])
        allow(use_case_double).to receive(:call).and_return(failure_result)
      end

      it 'returns failure result with user context' do
        result = subject.call

        expect(result).to be_failure
      end
    end
  end
end
