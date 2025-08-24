module Contracts
  class UnfollowContract < Dry::Validation::Contract
    params do
      required(:identity_id).filled(:integer)
      required(:id).filled(:integer)
    end

    rule(:identity_id, :id) do
      key.failure('cannot unfollow yourself') if values[:identity_id] == values[:id]
    end

    rule(:id) do
      key.failure('must be a positive integer') if value && value <= 0
    end

    rule(:id) do
      key.failure('followed user does not exist') if value && !MasterData::Repositories::User.new.exists?(value)
    end

    rule(:identity_id, :id) do
      key.failure('not followed user before') if value &&  Relationship::Repositories::Follow.new.find_by_identity(follower_id: values[:identity_id], followed_id: values[:id]).blank?
    end
  end
end
