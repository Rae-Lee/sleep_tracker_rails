module Contracts
  class FollowContract < Dry::Validation::Contract
    params do
      required(:identity_id).filled(:integer)
      required(:followed_id).filled(:integer)
    end

    rule(:identity_id, :followed_id) do
      key.failure('cannot follow yourself') if values[:identity_id] == values[:followed_id]
    end

    rule(:followed_id) do
      key.failure('must be a positive integer') if value && value <= 0
    end

    rule(:followed_id) do
      key.failure('followed user does not exist') if value && !MasterData::Repositories::User.new.exists?(value)
    end

    rule(:identity_id, :followed_id) do
      key.failure('has followed user before') if value &&  Relationship::Repositories::Follow.new.find_by_identity(follower_id: values[:identity_id], followed_id: values[:followed_id]).present?
    end
  end
end
