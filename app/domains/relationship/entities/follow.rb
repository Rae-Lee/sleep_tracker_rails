module Relationship
  module Entities
    class Follow < Boxenn::Entity
      attribute :follower_id, Types::Strict::Integer
      attribute :followed_id, Types::Strict::Integer
      def self.primary_keys
        %i[follower_id followed_id]
      end

      def valid?
        follower_id != followed_id
      end
    end
  end
end
