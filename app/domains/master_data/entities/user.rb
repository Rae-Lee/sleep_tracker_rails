module MasterData
  module Entities
    class User < Boxenn::Entity
      def self.primary_keys
        %i[id]
      end

      attribute? :id, Types::Integer.optional
      attribute? :name, Types::String.optional
    end
  end
end
