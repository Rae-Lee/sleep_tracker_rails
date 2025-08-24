module Contracts
  class FollowingsContract < Dry::Validation::Contract
    params do
      required(:identity_id).filled(:integer)
      optional(:page).maybe(:integer)
      optional(:per_page).maybe(:integer)
    end

    rule(:page) do
      key.failure('must be a positive integer') if value && value <= 0
    end

    rule(:per_page) do
      key.failure('must be a positive integer') if value && value <= 0
    end

    rule(:per_page) do
      key.failure('cannot exceed 50 records per page') if value && value > 50
    end
  end
end
