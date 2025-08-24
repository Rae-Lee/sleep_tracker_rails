module MasterData
  module Repositories
    class User < Homebrew::Repository
      option :entity, default: -> { Entities::User }

      option :source_wrapper, default: -> { Wrapper.new }
      option :record_mapper, default: -> { Mapper.new }
      option :factory, default: -> { Factory.new }

      class Mapper < Homebrew::SymmetricActiveRecord::Mapper
        param :entity, default: -> { Entities::User }
      end

      class Factory < Homebrew::SymmetricActiveRecord::Factory
        param :source, default: -> { MasterData::User }
        param :entity, default: -> { Entities::User }
      end

      class Wrapper < Homebrew::SymmetricActiveRecord::Wrapper
        param :source, default: -> { MasterData::User }
      end

      def exists?(id)
        source_wrapper.source.exists?(id: id)
      end
    end
  end
end
