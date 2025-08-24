module Relationship
  module Repositories
    class Follow < Homebrew::Repository
      option :entity, default: -> { Entities::Follow }

      option :source_wrapper, default: -> { Wrapper.new }
      option :record_mapper, default: -> { Mapper.new }
      option :factory, default: -> { Factory.new }

      class Mapper < Homebrew::SymmetricActiveRecord::Mapper
        param :entity, default: -> { Entities::Follow }
      end

      class Factory < Homebrew::SymmetricActiveRecord::Factory
        param :source, default: -> { Relationship::FollowRecord }
        param :entity, default: -> { Entities::Follow }
      end

      class Wrapper < Homebrew::SymmetricActiveRecord::Wrapper
        param :source, default: -> { Relationship::FollowRecord }

        def save(primary_keys, _attributes)
          lock_key = generate_lock_key(primary_keys)

          with_advisory_lock(lock_key) do
            source.create!(primary_keys)
          end
        rescue ActiveRecord::RecordNotUnique
          source.find_by(primary_keys)
        end

        def destroy(primary_keys)
          lock_key = generate_lock_key(primary_keys)

          with_advisory_lock(lock_key) do
            source.find_by(primary_keys)&.destroy!
          end
        end

        private

        def generate_lock_key(primary_keys)
          follower_id = primary_keys[:follower_id]
          followed_id = primary_keys[:followed_id]

          # Ensure consistent ordering to prevent deadlocks
          ids = [follower_id, followed_id].sort
          "follow_relationship_#{ids[0]}_#{ids[1]}"
        end
      end
    end
  end
end
