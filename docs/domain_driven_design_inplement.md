# Domain-Driven Design Implementation with Boxenn

This document outlines the Domain-Driven Design (DDD) implementation patterns used in the Sleep Tracker Rails API, leveraging the Boxenn framework for clean architecture and domain modeling.

## Table of Contents

- [Overview](#overview)
- [Entity Implementation](#entity-implementation)
- [Use Case Implementation](#use-case-implementation)
- [Repository Implementation](#repository-implementation)
- [Best Practices](#best-practices)
- [Examples](#examples)

---

## Overview

The application follows DDD principles using the **Boxenn** framework, which provides:
- Clean separation of concerns
- Type-safe domain modeling
- Consistent error handling with Dry::Monads
- Testable and maintainable code structure

### Core Components

1. **Entities**: Domain objects with identity and business rules
2. **Use Cases**: Business process orchestration
3. **Repositories**: Data access abstraction layer

---

## Entity Implementation

### Core Principles

**Entities** represent domain objects with unique identity and encapsulate business rules.

#### Requirements:
- **Must inherit from `Boxenn::Entity`**
- **Must define Primary Keys** for uniqueness
- **Domain data modification** through unified Repository interface
- **Object attribute constraints** defined within Entity (e.g., Enum validations)

### Implementation Pattern

```ruby
module DomainName
  module Entities
    class EntityName < Boxenn::Entity
      # Define primary keys for uniqueness
      def self.primary_keys
        %i[id] # or composite keys like %i[user_id sleep_at]
      end

      # Define attributes with types and constraints
      attribute? :id, Types::Integer.optional
      attribute? :name, Types::String.optional
      attribute? :status, Types::String.enum('active', 'inactive')

      # Business logic methods
      def active?
        status == 'active'
      end

      # Validation rules
      def valid?
        # Custom validation logic
        name.present? && status.present?
      end
    end
  end
end
```

---

## Use Case Implementation

### Core Principles

**Use Cases** orchestrate complete business processes and handle application logic.

#### Requirements:
- **Must inherit from `Boxenn::UseCase`**
- **Handle complete business processes** from start to finish
- **Use Dry::Monads** for error and success returns
- **Only one public method** that returns `Success` or `Failure`
- **Private methods returning Dry::Monads** use `yield` (Failure auto-returns)
- **Option parameter defaults use Proc** for external call overrides and test convenience

### Implementation Pattern

```ruby
module UseCases
  module DomainName
    class ActionName < Boxenn::UseCase
      # Dependencies with Proc defaults for testability
      option :repository, default: -> { DomainName::Repositories::EntityName.new }
      option :cache_service, default: -> { Cache::ServiceName }
      option :external_service, default: -> { ExternalService.new }

      # Single public method
      def steps(params)
        # Use yield for methods that return Dry::Monads
        # Failure will auto-return, Success continues
        validated_data = yield validate_input(params)
        entity = yield process_business_logic(validated_data)
        yield update_cache(entity)
        
        Success(build_response(entity))
      end

      private

      # Private methods return Dry::Monads objects
      def validate_input(params)
        return Failure(:invalid_params) unless params[:required_field]
        Success(params)
      end

      def process_business_logic(data)
        entity = repository.save(data)
        Success(entity)
      rescue StandardError => e
        Failure("Business logic failed: #{e.message}")
      end

      def update_cache(entity)
        cache_service.invalidate_cache
        Success()
      end

      # Helper methods can return regular objects
      def build_response(entity)
        {
          id: entity.id,
          status: 'completed',
          data: entity.to_h
        }
      end
    end
  end
end
```

---

## Repository Implementation

### Core Principles

**Repositories** provide data access abstraction and handle Entity persistence.

#### Requirements:
- **Must inherit from `Boxenn::Repository`**
- **Handle data access** between domain and infrastructure
- **Define Wrapper, Factory, Mapper** for data transformation
  - **Wrapper**: Hash to Database transformation
  - **Factory**: Database to Entity transformation  
  - **Mapper**: Field mapping between layers
- **Inputs/outputs preferably Entity types**
- **Create/Update both use `save`** method, determined by Primary Key existence

### Implementation Pattern

```ruby
module DomainName
  module Repositories
    class EntityName < Homebrew::Repository
      option :entity, default: -> { Entities::EntityName }

      option :source_wrapper, default: -> { Wrapper.new }
      option :record_mapper, default: -> { Mapper.new }
      option :factory, default: -> { Factory.new }

      # Mapper: Field mapping between layers
      class Mapper < Homebrew::SymmetricActiveRecord::Mapper
        param :entity, default: -> { Entities::EntityName }
      end

      # Factory: Database to Entity transformation
      class Factory < Homebrew::SymmetricActiveRecord::Factory
        param :source, default: -> { ActiveRecordModel }
        param :entity, default: -> { Entities::EntityName }
      end

      # Wrapper: Hash to Database transformation
      class Wrapper < Homebrew::SymmetricActiveRecord::Wrapper
        param :source, default: -> { ActiveRecordModel }

        def save(primary_keys, attributes)
          # Custom save logic with business rules
          # Create or Update determined by Primary Key
        end
      end

      # Repository methods work with Entities
      def find_by_id(id)
        record = source_wrapper.source.find(id)
        factory.build(record)
      end

      def save(entity)
        primary_keys = entity.class.primary_keys.map { |key| [key, entity.send(key)] }.to_h
        attributes = entity.to_h.except(*entity.class.primary_keys)
        
        source_wrapper.save(primary_keys, attributes)
      end
    end
  end
end
```

---

## Best Practices

### Entity Best Practices

1. **Keep Entities Pure**: No external dependencies, only domain logic
2. **Immutable by Default**: Use `attribute?` for optional fields
3. **Validation in Entities**: Business rules belong in the domain
4. **Meaningful Primary Keys**: Choose keys that represent business identity

```ruby
# Good: Business-meaningful primary key
def self.primary_keys
  %i[user_id sleep_at]  # Represents unique sleep session
end

# Avoid: Generic auto-increment ID when business key exists
def self.primary_keys
  %i[id]  # Less meaningful for domain
end
```

### Use Case Best Practices

1. **Single Responsibility**: One use case per business process
2. **Dependency Injection**: Use `option` with Proc defaults
3. **Error Handling**: Always return `Success` or `Failure`
4. **Testability**: Proc defaults allow easy mocking

```ruby
# Good: Testable dependencies
option :repository, default: -> { Domain::Repositories::Entity.new }

# In tests:
use_case = UseCase.new(repository: mock_repository)
```

### Repository Best Practices

1. **Entity-Centric**: Work with Entities, not raw data
2. **Thread Safety**: Use advisory locks for concurrent operations
3. **Consistent Interface**: `save` for both create and update
4. **Separation of Concerns**: Wrapper handles persistence logic

```ruby
# Good: Entity input/output
def save(entity)
  primary_keys = extract_primary_keys(entity)
  attributes = extract_attributes(entity)
  source_wrapper.save(primary_keys, attributes)
end

# Avoid: Hash-based interface
def save(hash_data)
  # Less type-safe, harder to maintain
end
```

---

## Examples

### Complete Domain Implementation

Here's how all three components work together:

```ruby
# 1. Entity Definition
module TrackManagement
  module Entities
    class SleepRecord < Boxenn::Entity
      def self.primary_keys
        %i[user_id sleep_at]
      end

      attribute? :user_id, Types::Integer.optional
      attribute? :sleep_at, Types::Params::DateTime.optional
      attribute? :wake_at, Types::Params::DateTime.optional

      def incomplete?
        sleep_at && wake_at.nil?
      end
    end
  end
end

# 2. Repository Implementation
module TrackManagement
  module Repositories
    class SleepRecord < Homebrew::Repository
      # ... (implementation as shown above)
    end
  end
end

# 3. Use Case Orchestration
module UseCases
  module SleepRecord
    class ClockInSleepRecord < Boxenn::UseCase
      option :sleep_record_repo, default: -> { TrackManagement::Repositories::SleepRecord.new }

      def steps(params)
        entity = build_entity(params)
        saved_entity = yield save_entity(entity)
        result = yield build_response(saved_entity)
        
        Success(result)
      end

      private

      def build_entity(params)
        TrackManagement::Entities::SleepRecord.new(
          user_id: params[:identity_id],
          sleep_at: params[:sleep_at],
          wake_at: params[:wake_at]
        )
      end

      def save_entity(entity)
        sleep_record_repo.save(entity)
        Success(entity)
      rescue StandardError => e
        Failure("Save failed: #{e.message}")
      end

      def build_response(entity)
        Success({
          user_id: entity.user_id,
          status: entity.incomplete? ? 'sleeping' : 'completed',
          data: entity.to_h
        })
      end
    end
  end
end

# 4. Controller Usage
class Api::V1::SleepRecords::ClockInsController < BaseController
  def create
    result = UseCases::SleepRecord::ClockInSleepRecord.new.call(request_params)
    
    if result.success?
      render json: result.value!
    else
      render json: { error: result.failure }, status: :unprocessable_entity
    end
  end
end
```

This implementation provides:
- **Type Safety**: Entities define clear contracts
- **Error Handling**: Consistent Success/Failure patterns
- **Testability**: Dependency injection with Proc defaults
- **Maintainability**: Clear separation of concerns
- **Thread Safety**: Advisory locks in repositories
- **Business Logic**: Domain rules encapsulated in entities

---

## Conclusion

The Boxenn framework provides a robust foundation for implementing Domain-Driven Design in Rails applications. By following these patterns, you achieve:

- **Clean Architecture**: Clear separation between domain, application, and infrastructure layers
- **Type Safety**: Strong typing with dry-types integration
- **Error Handling**: Consistent monadic error handling
- **Testability**: Dependency injection and pure domain logic
- **Maintainability**: Well-organized, predictable code structure

This approach scales well as the application grows and makes it easier to reason about complex business logic while maintaining high code quality.