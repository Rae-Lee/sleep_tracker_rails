module Homebrew
  module SymmetricActiveRecord
    class Mapper < Boxenn::Repositories::RecordMapper
      extend Dry::Initializer
      param :entity

      NIL_SET = [nil, ''].freeze

      def build(value)
        batch_mapping(value: value, mapper: mapper)
      end

      private

      def mapper
        entity.attribute_names.map { |x| [x, x] }.to_h
      end

      def batch_mapping(value:, mapper:)
        case value
        when Array
          value.map do |item|
            mapping(hash: item, mapper: mapper)
          end
        when Hash
          mapping(hash: value, mapper: mapper)
        end
      end

      def mapping(hash:, mapper:)
        result = {}
        hash.each do |key, value|
          next if !mapper.key?(key) || NIL_SET.include?(value)

          if mapper[key].is_a?(Array)
            result[mapper[key].first] = batch_mapping(value: value, mapper: mapper[key][1])
          else
            result[mapper[key]] = value.is_a?(Hash) ? value.compact : value
          end
        end
        result
      end
    end
  end
end
