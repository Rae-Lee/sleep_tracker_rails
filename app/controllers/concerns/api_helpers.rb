module ApiHelpers
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    rescue_from StandardError, with: :render_not_found
  end

  def request_params
    hash = params.to_unsafe_hash
    hash[:identity_id] = current_user.id if current_user.present?
    hash
  end

  def current_user
    @current_user ||= MasterData::User.first
  end

  def validated_params(contract_class, params)
    result = contract_class.new.call(params)
    if result.failure?
      render json: { error: 'Validation failed', errors: result.errors.to_h }, status: :unprocessable_entity and return
    end
    result.to_h
  end

  def serialize_collection(collection, serializer_class)
    serializer_class.new(collection).serialize
  end

  def serialize_resource(resource, serializer_class)
    serializer_class.new(resource).serialize
  end

  def create_pagination_object(page: 1, per_page: 10, total_count: 0)
    page = page.to_i
    per_page = per_page.to_i
    total_count = total_count.to_i

    {
      current_page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: (total_count.to_f / per_page).ceil
    }
  end

  def handle_use_case_result(result)
    error = result.failure.first
    error_message = error.message

    case error
    when ActiveRecord::RecordNotFound
      render json: { error: 'Record not found', message: error_message }, status: :not_found
    when ActiveRecord::RecordInvalid
      render json: { error: 'Validation failed', message: error_message }, status: :unprocessable_entity
    else
      render json: { error: 'Internal server error', message: error_message }, status: :internal_server_error
    end
  end

  private

  def render_not_found(exception)
    render json: { error: 'Record not found', message: exception.message }, status: :not_found
  end

  def render_unprocessable_entity(exception)
    render json: { error: 'Validation failed', message: exception.message }, status: :unprocessable_entity
  end
end
