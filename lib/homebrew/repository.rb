module Homebrew
  class Repository < Boxenn::Repository
    def find_by_identity(**attributes)
      non_primary_keys_provided = (attributes.keys - factory.primary_keys).empty? && (factory.primary_keys - attributes.keys).empty?
      unless non_primary_keys_provided
        raise InvalidPrimaryKey.new(class_name: self.class.name, provided: attributes.keys,
                                    required: factory.primary_keys)
      end

      record = retrieve_record(**attributes)
      record.nil? ? nil : build(record)
    end
  end
end
