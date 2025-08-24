module TrackManagement
  module Repositories
    class SleepRecord < Homebrew::Repository
      option :entity, default: -> { Entities::SleepRecord }

      option :source_wrapper, default: -> { Wrapper.new }
      option :record_mapper, default: -> { Mapper.new }
      option :factory, default: -> { Factory.new }

      class Mapper < Homebrew::SymmetricActiveRecord::Mapper
        param :entity, default: -> { Entities::SleepRecord }
      end

      class Factory < Homebrew::SymmetricActiveRecord::Factory
        param :source, default: -> { TrackManagement::SleepRecord }
        param :entity, default: -> { Entities::SleepRecord }
      end

      class Wrapper < Homebrew::SymmetricActiveRecord::Wrapper
        param :source, default: -> { TrackManagement::SleepRecord }

        def save(primary_keys, attributes)
          user_id = primary_keys[:user_id]
          lock_key = "sleep_record_user_#{user_id}"

          with_advisory_lock(lock_key) do
            incomplete_record = source.find_by(user_id: user_id, wake_at: nil)

            if incomplete_record && attributes[:wake_at] && attributes[:sleep_at].to_i == incomplete_record.sleep_at.to_i
              clock_out(incomplete_record, attributes)
            elsif !incomplete_record && attributes[:wake_at].nil?
              clock_in(user_id, attributes)
            end
          end
        end

        private

        def clock_in(user_id, attributes)
          source.create!(
            user_id: user_id,
            sleep_at: attributes[:sleep_at],
            sleep_timezone: attributes[:sleep_timezone] || 'UTC',
            wake_at: nil,
            wake_timezone: nil,
            duration: nil
          )
        end

        def clock_out(record, attributes)
          wake_at = attributes[:wake_at]
          wake_timezone = attributes[:wake_timezone] || record.sleep_timezone
          sleep_at = attributes[:sleep_at]
          duration = (wake_at.utc - sleep_at.utc).to_i

          record.update!(
            wake_at: wake_at,
            wake_timezone: wake_timezone,
            duration: duration
          )
        end
      end

      def find_by_user_id(user_id:, page: 1, per_page: 10)
        records = source_wrapper.source.where(user_id: user_id).order(created_at: :desc)

        records = records.limit(per_page).offset((page - 1) * per_page)

        records.map { |record| factory.build(record) }
      end

      def count_by_user_id(user_id:)
        source_wrapper.source.where(user_id: user_id).count
      end
    end
  end
end
