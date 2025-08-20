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
  end
end
