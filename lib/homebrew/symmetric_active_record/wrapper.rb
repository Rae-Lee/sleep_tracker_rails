module Homebrew
  module SymmetricActiveRecord
    class Wrapper < Boxenn::Repositories::SourceWrapper
      param :source, default: proc {}

      def find_by(primary_keys)
        records = source.where(primary_keys)
        raise(StandardError, "#{source} records are not unique.") if records.size > 1

        records.first
      end

      private

      def with_advisory_lock(lock_key, timeout: 10)
        lock_id = lock_key.hash.abs
        retries = 0

        loop do
          acquired = ActiveRecord::Base.connection.execute(
            "SELECT pg_try_advisory_lock(#{lock_id}) as acquired"
          ).first['acquired']

          if acquired
            begin
              return yield
            ensure
              ActiveRecord::Base.connection.execute(
                "SELECT pg_advisory_unlock(#{lock_id})"
              )
            end
          else
            raise StandardError, "Could not acquire lock for #{lock_key}" if retries >= timeout * 10

            retries += 1
            sleep(0.1)
          end
        end
      end
    end
  end
end
