require 'rails_helper'

RSpec.describe 'Api::V1::SleepRecords::ClockIns', type: :request do
  let!(:user) { create(:user) }
  let(:headers) { { 'ACCEPT' => 'application/json' } }
  let(:cache_service) { instance_double(Cache::SleepRecordCacheService) }

  let(:valid_params) do
    {
      identity_id: user.id,
      sleep_at: "2025-08-23T22:30:00Z",
      sleep_timezone: 'Asia/Taipei'
    }
  end

  before do
    allow_any_instance_of(Api::V1::BaseController).to receive(:current_user).and_return(user)
  end

  describe 'POST /api/v1/sleep_records/clock_in' do
    context 'when clocking in (starting sleep)' do
      before do
        allow(Cache::SleepRecordCacheService).to receive(:new).and_return(cache_service)
        allow(cache_service).to receive(:invalidate_cache_key)
        allow(cache_service).to receive(:cache_data)
      end

      it 'successfully creates a sleep record' do
     
        post '/api/v1/sleep_records/clock_in', params: valid_params, headers: headers
    
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
        json[:data] = JSON.parse(json[:data], symbolize_names: true) if json[:data].is_a?(String)

        expect(json).to include(:user_id, :data, :pagination)
        expect(json[:user_id]).to eq(user.id)
        expect(json[:data]).to be_an(Array)
        expect(json[:data].size).to eq(1)
        
        sleep_record_data = json[:data].first
        expect(Time.parse(sleep_record_data[:sleep_at])).to eq(valid_params[:sleep_at])
        expect(sleep_record_data[:wake_at]).to be_nil
        expect(sleep_record_data[:sleep_timezone]).to eq('Asia/Taipei')
        expect(Time.parse(sleep_record_data[:sleep_at_in_timezone])).to eq(Time.parse(valid_params[:sleep_at]).in_time_zone("Asia/Taipei"))
        expect(sleep_record_data[:status]).to eq('sleeping')
      end

      it 'returns pagination information' do
        post '/api/v1/sleep_records/clock_in', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)

        expect(json[:pagination][:current_page]).to eq(1)
        expect(json[:pagination][:per_page]).to eq(10)
        expect(json[:pagination][:total_count]).to eq(1)
        expect(json[:pagination][:total_pages]).to eq(1)
      end

      it 'invalidates cache after creating sleep record' do
        post '/api/v1/sleep_records/clock_in', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        expect(cache_service).to have_received(:invalidate_cache_key)
      end

      it 'caches the result data' do
        post '/api/v1/sleep_records/clock_in', params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        expect(cache_service).to have_received(:cache_data)
      end
    end

    context 'when clocking out (ending sleep)' do
      let!(:incomplete_sleep_record) do
        create(:sleep_record, :incomplete, 
               user: user, 
               sleep_at: "2025-08-23T22:30:00Z",
               sleep_timezone: 'Asia/Taipei')
      end

      let(:clock_out_params) do
        {
          identity_id: user.id,
          sleep_at: incomplete_sleep_record.sleep_at,
          wake_at: incomplete_sleep_record.sleep_at + 7.hours,
        }
      end

      before do
        allow(Cache::SleepRecordCacheService).to receive(:new).and_return(cache_service)
        allow(cache_service).to receive(:invalidate_cache_key)
        allow(cache_service).to receive(:cache_data)
      end

      it 'successfully completes the sleep record' do
        post '/api/v1/sleep_records/clock_in', params: clock_out_params, headers: headers
            
        expect(response).to have_http_status(:ok)
        records = TrackManagement::SleepRecord.all
        expect(records.count).to eq(1)

        json = JSON.parse(response.body, symbolize_names: true)
        json[:data] = JSON.parse(json[:data], symbolize_names: true) if json[:data].is_a?(String)
                
        sleep_record_data = json[:data].first
  
        expect(Time.parse(sleep_record_data[:wake_at])).to eq(clock_out_params[:wake_at])
        expect(sleep_record_data[:status]).to eq('completed')
        expect(sleep_record_data[:sleep_timezone]).to eq('Asia/Taipei')
        expect(sleep_record_data[:wake_timezone]).to eq('Asia/Taipei')
      end

      it 'calculates duration correctly' do
        post '/api/v1/sleep_records/clock_in', params: clock_out_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
        json[:data] = JSON.parse(json[:data], symbolize_names: true) if json[:data].is_a?(String)
                
        sleep_record_data = json[:data].first
        expect(sleep_record_data[:duration]).to eq(25200)
      end

      it 'invalidates cache after completing sleep record' do
        post '/api/v1/sleep_records/clock_in', params: clock_out_params, headers: headers

        expect(response).to have_http_status(:ok)
        expect(cache_service).to have_received(:invalidate_cache_key)
      end
    end

    context 'when parameters are invalid' do
      it 'returns error for missing sleep_at' do
        invalid_params = valid_params.except(:sleep_at)
        
        post '/api/v1/sleep_records/clock_in', params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for invalid timezone' do
        invalid_params = valid_params.merge(sleep_timezone: 'Invalid/Timezone')
        
        post '/api/v1/sleep_records/clock_in', params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when wake_at is before sleep_at' do
        invalid_params = valid_params.merge(
          wake_at: 3.hours.ago.iso8601  # Before sleep_at (2.hours.ago)
        )
        
        post '/api/v1/sleep_records/clock_in', params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
