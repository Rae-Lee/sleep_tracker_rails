module Api
  module V1
    module Followings
      class SleepRankingsController < BaseController
        def index
          params_hash = validated_params(Contracts::FollowingsContract, request_params)
           return if performed?

          result = UseCases::Followings::GetSleepRanking.new.call(params_hash)
          if result.failure?
            handle_use_case_result(result)
            return
          end

          result = result.value!
          
          render json:{
            user_id: result[:user_id],
            week_start: result[:week_start],
            week_end: result[:week_end],
            data: serialize_collection(result[:rankings], Serializers::FollowingsSleepRankingSerializer),
            pagination: create_pagination_object(
              page: result[:pagination][:page],
              per_page: result[:pagination][:per_page],
              total_count: result[:pagination][:total_count]
            )
          }
        end
      end
    end
  end
end
