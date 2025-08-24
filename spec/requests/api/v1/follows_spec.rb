require 'rails_helper'

RSpec.describe 'Api::V1::Follows', type: :request do
  let(:follower) { create(:user) }
  let(:followed_user) { create(:user) }
  let(:base_path) { '/api/v1/follows' }
  let(:headers) { { 'ACCEPT' => 'application/json' } }
  let(:cache_service) { instance_double(Cache::FollowingsSleepRecordsCacheService) }

  before do
    allow_any_instance_of(Api::V1::BaseController).to receive(:current_user).and_return(follower)
  end

  describe 'POST /api/v1/follows' do
    context 'with valid parameters' do
      let(:follow_params) do
        {
          identity_id: follower.id,
          followed_id: followed_user.id
        }
      end

      it 'successfully creates a follow relationship' do
        post base_path, params: follow_params, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
    
        follow_record = Relationship::FollowRecord.last
        expect(follow_record.follower_id).to eq(follower.id)
        expect(follow_record.followed_id).to eq(followed_user.id)
      end

      it 'returns serialized follow data' do
        post base_path, params: follow_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
        json[:data] = JSON.parse(json[:data], symbolize_names: true) if json[:data].is_a?(String)
        
        expect(json[:user_id]).to eq(follower.id)
        expect(json[:data][:followed_id]).to eq(followed_user.id)
        expect(json[:data][:followed_name]).to eq(followed_user.name)
      end

      it 'invalidates followings cache after creating follow' do
        allow(Cache::FollowingsSleepRecordsCacheService).to receive(:new).and_return(cache_service)
        allow(cache_service).to receive(:cache_exists?).and_return(true)
        allow(cache_service).to receive(:invalidate_all_user_cache)

        post base_path, params: follow_params, headers: headers

        expect(cache_service).to have_received(:invalidate_all_user_cache)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when trying to follow yourself' do
        invalid_params = {
          identity_id: follower.id,
          followed_id: follower.id
        }
        
        post base_path, params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for non-existent followed user' do
        invalid_params = {
          identity_id: follower.id,
          followed_id: 99999
        }
        
        post base_path, params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when follow relationship already exists' do
      before do
        create(:follow_record, follower: follower, followed: followed_user)
      end

      let(:follow_params) do
        {
          identity_id: follower.id,
          followed_id: followed_user.id
        }
      end

      it 'handles duplicate follow attempts gracefully' do
        post base_path, params: follow_params, headers: headers
         expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/follows/:id' do
    let!(:follow_record) { create(:follow_record, follower: follower, followed: followed_user) }

    context 'with valid parameters' do
      let(:unfollow_params) do
        {
          identity_id: follower.id,
          id: followed_user.id
        }
      end

      it 'successfully removes the follow relationship' do
        delete "#{base_path}/#{followed_user.id}", params: unfollow_params, headers: headers
   
        expect(response).to have_http_status(:ok)
      end

      it 'invalidates followings cache after unfollowing' do
        allow(Cache::FollowingsSleepRecordsCacheService).to receive(:new).and_return(cache_service)
        allow(cache_service).to receive(:cache_exists?).and_return(true)
        allow(cache_service).to receive(:invalidate_all_user_cache)

        delete "#{base_path}/#{followed_user.id}", params: unfollow_params, headers: headers

        expect(cache_service).to have_received(:invalidate_all_user_cache)
      end
    end
    
    context 'with invalid parameters' do
      it 'returns error when trying to unfollow yourself' do
        invalid_params = {
          identity_id: follower.id,
          id: follower.id
        }
        
        delete "#{base_path}/#{follower.id}", params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when not following the user' do
        other_user = create(:user)
        invalid_params = {
          identity_id: follower.id,
          id: other_user.id
        }
        
        delete "#{base_path}/#{other_user.id}", params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for non-existent followed user' do
        invalid_params = {
          identity_id: follower.id,
          id: 99999
        }
        
        delete "#{base_path}/99999", params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
