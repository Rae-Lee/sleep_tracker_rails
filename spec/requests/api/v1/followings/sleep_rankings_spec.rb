require 'rails_helper'

RSpec.describe 'Api::V1::Followings::SleepRankings', type: :request do
  let!(:user) { create(:user) }
  let(:headers) { { 'ACCEPT' => 'application/json' } }
  let!(:followed_users) { create_list(:user, 3) }
  let!(:follows) { followed_users.map { |fu| create(:follow_record, follower: user, followed: fu) } }
  let!(:followings_records) do
    followed_users.each_with_index.map do |followed_user, index|
      duration_hours = [8, 7, 6][index]
      previous_week_start = Time.current.in_time_zone('Asia/Taipei').beginning_of_week(:monday) - 1.week
      sleep_time = previous_week_start + 22.hours
      wake_time = sleep_time + duration_hours.hours

      create(:sleep_record,
        user: followed_user,
        sleep_at: sleep_time,
        wake_at: wake_time,
        sleep_timezone: 'Asia/Taipei',
        wake_timezone: 'Asia/Taipei',
        duration: duration_hours * 3600
      )
    end
  end
  let(:cache_service) { instance_double(Cache::FollowingsSleepRecordsCacheService) }

  let(:valid_params) do
    {
      identity_id: user.id,
      page: 1,
      per_page: 10
    }
  end

  before do
    allow_any_instance_of(Api::V1::BaseController).to receive(:current_user).and_return(user)

    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW track_management_followings_weekly_sleep_rankings;')
  end

  describe 'GET /api/v1/followings/sleep_ranking' do
    context 'when parameters are valid and have to cache' do
      before do
        allow(Cache::FollowingsSleepRecordsCacheService).to receive(:new).and_return(cache_service)
        allow(cache_service).to receive(:increment_query_count)
        allow(cache_service).to receive(:cache_exists?).and_return(false)
        allow(cache_service).to receive(:should_cache?).and_return(true)
        allow(cache_service).to receive(:cache_data).and_return(nil)
      end

      it 'returns the sleep ranking data' do    
        get '/api/v1/followings/sleep_ranking', params: valid_params, headers: headers
       
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
      
        expect(json).to include(:user_id, :week_start, :week_end, :data, :pagination)
        expect(json[:user_id]).to eq(user.id)
      end

      it 'returns the weekly sleep rankings of followed users' do
        get '/api/v1/followings/sleep_ranking', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
        json[:data] = JSON.parse(json[:data], symbolize_names: true) if json[:data].is_a?(String)

        expect(json[:data].size).to eq(3)
        expect(json[:data].first[:followed_id]).to eq(followed_users.first.id)
        expect(json[:data].second[:followed_id]).to eq(followed_users.second.id)
        expect(json[:data].last[:followed_id]).to eq(followed_users.last.id)
        expect(json[:data].first[:duration]).to eq(28800)
        expect(json[:data].first[:sleep_at]).to eq(followings_records.first.sleep_at.to_datetime.iso8601)
        expect(json[:data].first[:wake_at]).to eq(followings_records.first.wake_at.to_datetime.iso8601)
        expect(json[:data].first[:sleep_timezone]).to eq('Asia/Taipei')
        expect(json[:data].first[:wake_timezone]).to eq('Asia/Taipei')    
      end

      it 'returns pagination information' do
        get '/api/v1/followings/sleep_ranking', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)

        expect(json[:pagination][:current_page]).to eq(1)
        expect(json[:pagination][:per_page]).to eq(10)
        expect(json[:pagination][:total_count]).to eq(3)
        expect(json[:pagination][:total_pages]).to eq(1)
      end

      it 'increments the query count' do
        get '/api/v1/followings/sleep_ranking', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        expect(cache_service).to have_received(:increment_query_count)
      end

      it 'caches data when should_cache returns true' do
        get '/api/v1/followings/sleep_ranking', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        expect(cache_service).to have_received(:cache_data)
      end
    end

    context 'when parameters are valid and do not have to cache' do
      before do
        allow(Cache::FollowingsSleepRecordsCacheService).to receive(:new).and_return(cache_service)
        allow(cache_service).to receive(:increment_query_count)
        allow(cache_service).to receive(:cache_exists?).and_return(false)
        allow(cache_service).to receive(:should_cache?).and_return(false)
        allow(cache_service).to receive(:cache_data).and_return(nil)
      end

      it 'do not caches data when should_cache returns false' do
        get '/api/v1/followings/sleep_ranking', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        expect(cache_service).not_to have_received(:cache_data)
      end  
    end

    context 'when user has no followings' do
      let(:user_with_no_followings) { create(:user) }
      let(:ranking_params) do
        {
          identity_id: user_with_no_followings.id,
          page: 1,
          per_page: 10
        }
      end

      before do
        allow_any_instance_of(Api::V1::BaseController).to receive(:current_user).and_return(user_with_no_followings)

        ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW track_management_followings_weekly_sleep_rankings;')
        allow(Cache::FollowingsSleepRecordsCacheService).to receive(:new).and_return(cache_service)
        allow(cache_service).to receive(:increment_query_count)
        allow(cache_service).to receive(:cache_exists?).and_return(false)
        allow(cache_service).to receive(:should_cache?).and_return(false)
      end

      it 'returns empty data array with correct structure' do
        get '/api/v1/followings/sleep_ranking', params: ranking_params, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
        json[:data] = JSON.parse(json[:data], symbolize_names: true) if json[:data].is_a?(String)


        expect(json[:user_id]).to eq(user_with_no_followings.id)
        expect(json[:data]).to be_empty
        expect(json[:pagination][:total_count]).to eq(0)
      end
    end

    context 'with cached data' do
      let!(:record_array) do
        create(:track_management_entities_sleep_record, duration: 28800, user_id:1)
      end

      let(:cached_response) do
        {
          rankings: [record_array],
          total_count: 1
        }
      end

      before do
        allow(Cache::FollowingsSleepRecordsCacheService).to receive(:new).and_return(cache_service)
        allow(cache_service).to receive(:increment_query_count)
        allow(cache_service).to receive(:cache_exists?).and_return(true)
        allow(cache_service).to receive(:fetch_cached_entities).and_return(cached_response)
        allow(cache_service).to receive(:should_cache?).and_return(false)
      end

      it 'returns cached data when cache exists' do
        get '/api/v1/followings/sleep_ranking', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
        
        json[:data] = JSON.parse(json[:data], symbolize_names: true) if json[:data].is_a?(String)
        expect(json[:data].first[:followed_id]).to eq(1)
        expect(json[:data].first[:duration]).to eq(28800)
      end
    end

    context 'when parameters are invalid' do
      it 'returns an error for invalid page parameter' do
        get '/api/v1/followings/sleep_ranking', params: { identity_id: user.id, page: -1, per_page: 10 }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
