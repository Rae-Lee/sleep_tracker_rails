module Api
  module V1
    module SleepRecords
        class ClockInsController < BaseController
        def create
            params_hash = validated_params(Contracts::ClockInContract, request_params)
             return if performed?

            result = UseCases::SleepRecord::ClockInSleepRecord.new.call(params_hash)

            if result.failure?
                handle_use_case_result(result)
                return
            end

            result = result.value!
            render json: {
            user_id: result[:user_id],
            data: serialize_collection(result[:sleep_records], Serializers::SleepRecordsSerializer),
            pagination: create_pagination_object(**result[:pagination])
            }
        end
      end
    end
  end
end
