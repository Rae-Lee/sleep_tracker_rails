module Version
  module V1
    class Base < Grape::API
      version 'v1', using: :path
      format :json
      prefix :api

      rescue_from ActiveRecord::RecordNotFound do |e|
        error!({ error: 'Record not found', message: e.message }, 404)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        error!({ error: 'Validation failed', message: e.message }, 422)
      end

      rescue_from Dry::Validation::Result do |e|
        error!({ error: 'Validation failed', errors: e.errors.to_h }, 422)
      end

      helpers do
        def validate_params(contract_class, params)
          result = contract_class.new.call(params)
          error!({ error: 'Validation failed', errors: result.errors.to_h }, 422) if result.failure?
          result.to_h
        end

        def serialize_collection(collection, serializer_class)
          serializer_class.new(collection).serialize
        end

        def serialize_resource(resource, serializer_class)
          serializer_class.new(resource).serialize
        end
      end

      mount Version::V1::SleepRecordsAPI
      mount Version::V1::FollowsAPI
      mount Version::V1::FollowingsAPI
    end
  end
end
