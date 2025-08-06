module Homebrew
  module SymmetricActiveRecord
    class Factory < Boxenn::Repositories::Factory
      param :entity
      param :source
      
      def build(source_object)
        hash = build_entity_hash(source_object)
        entity.new(hash)
      end

      private

      def build_entity_hash(source_object)
        hash = build_symmetric_hash(source_object)
        hash.merge(build_specialized_hash(source_object))
      end

      def build_specialized_hash(_source_object)
        {}
      end

      def build_symmetric_hash(source_object, source_class: source, entity_class: entity)
        source_keys = source_class.attribute_names.map(&:to_sym)
        entity_keys = entity_class.attribute_names
        selected_keys = source_keys & entity_keys
        source_object.as_json.deep_symbolize_keys.slice(*selected_keys)
      end
    end
  end
end
