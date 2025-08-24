module TrackManagement
  module Entities
    class SleepRecord < Boxenn::Entity
      def self.primary_keys
        %i[user_id sleep_at]
      end

      attribute? :user_id, Types::Integer.optional
      attribute? :user_name, Types::String.optional
      attribute? :sleep_at, Types::Params::DateTime.optional
      attribute? :wake_at, Types::Params::DateTime.optional
      attribute? :duration, Types::Integer.optional
      attribute? :sleep_timezone, Types::String.optional
      attribute? :wake_timezone, Types::String.optional

      def sleep_timezone
        return nil unless sleep_at.present?

        attributes[:sleep_timezone] || 'UTC'
      end

      def wake_timezone
        return nil unless wake_at.present?

        attributes[:wake_timezone] || 'UTC'
      end

      def sleep_at_in_timezone
        return nil unless sleep_at.present?

        sleep_at.in_time_zone(sleep_timezone)
      end

      def wake_at_in_timezone
        return nil unless wake_at.present?

        wake_at.in_time_zone(wake_timezone)
      end

      def incomplete?
        sleep_at && wake_at.nil?
      end
    end
  end
end
