module Contracts
  class ClockInContract < Dry::Validation::Contract
    params do
      required(:identity_id).filled(:integer)
      required(:sleep_at).filled(:date_time)
      optional(:wake_at).maybe(:date_time)
      optional(:sleep_timezone).maybe(:string)
      optional(:wake_timezone).maybe(:string)
    end

    rule(:sleep_timezone) do
      if value && !::ActiveSupport::TimeZone[value]
        key.failure('must be a valid timezone')
      end
    end

    rule(:wake_timezone) do
       if value && !::ActiveSupport::TimeZone[value]
         key.failure('must be a valid timezone')
      end
    end

    rule(:wake_at) do
      if values[:sleep_at] && values[:wake_at] && values[:sleep_at] >= values[:wake_at]
        key.failure('must be after sleep_at')
      end
    end

    rule(:sleep_at, :wake_at, :identity_id) do
      existing_record = TrackManagement::Repositories::SleepRecord.new.find_by_identity(
        user_id: values[:identity_id],
        sleep_at: values[:sleep_at]
      )
      if values[:sleep_at] && values[:wake_at]        
        if existing_record && existing_record.wake_at.present?
          key.failure('a complete record with the same sleep_at time already exists')
        elsif existing_record.blank?
          key.failure('no incomplete record found with the given sleep_at time to clock out')
        end
      elsif values[:sleep_at] && values[:wake_at].nil?
        if existing_record
          key.failure('an incomplete record with the same sleep_at time already exists')
        end
      end
    end
  end
end
