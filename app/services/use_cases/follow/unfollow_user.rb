module UseCases
  module Follow
    class UnfollowUser < Boxenn::UseCase
      option :follow_repo, default: -> { Relationship::Repositories::Follow.new }
      option :cache_service_class, default: -> { Cache::FollowingsSleepRecordsCacheService }
      option :follow_entity_class, default: -> { Relationship::Entities::Follow }

      PAGE = 1

      def steps(params)
        follower_id = params[:identity_id]
        followed_id = params[:id]
        
        destroy_follow_relationship(follower_id: follower_id, followed_id: followed_id)
        invalidate_cache(user_id: follower_id)
        
        Success()
      end

      private

      def destroy_follow_relationship(follower_id:, followed_id:)
        unfollow_entity = follow_entity_class.new(
          follower_id: follower_id,
          followed_id: followed_id
        )

        follow_repo.destroy(unfollow_entity)
      end

      def invalidate_cache(user_id:)
        cache_service = cache_service_class.new(user_id: user_id, page: PAGE)
        cache_service.invalidate_all_user_cache
      end
    end
  end
end
