module Api
  module V1
    class FollowsController < BaseController
      def create
        params_hash = validated_params(Contracts::FollowContract, request_params)
        return if performed?

        result = UseCases::Follow::FollowUser.new.call(params_hash)
      
        if result.failure?
            handle_use_case_result(result)
            return
        end
        render json: serialize_resource(result.value!, Serializers::FollowSerializer)
      end

      def destroy
        validated_params = validated_params(Contracts::UnfollowContract, request_params)
        return if performed?
        
        result = UseCases::Follow::UnfollowUser.new.call(validated_params)
        
        if result.failure?
            handle_use_case_result(result)
            return
        end

        render json: { message: 'Successfully unfollowed user' }
      end
    end
  end
end
