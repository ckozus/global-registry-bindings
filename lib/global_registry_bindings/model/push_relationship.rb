# frozen_string_literal: true

require 'global_registry_bindings/workers/push_relationship_worker'
require 'global_registry_bindings/workers/delete_entity_worker'

module GlobalRegistry #:nodoc:
  module Bindings #:nodoc:
    module Model #:nodoc:
      module PushRelationship
        extend ActiveSupport::Concern

        included do
          after_commit :push_relationships_to_global_registry_async, on: %i[create update]
          after_commit :delete_relationships_from_global_registry_async, on: %i[destroy]
        end

        def push_relationships_to_global_registry_async(*types)
          types = types.empty? ? self.class.global_registry_relationship_types : types
          types.each do |type|
            action = global_registry_relationship_change_action(type)
            send("global_registry_relationship_async_#{action}".to_sym, type)
          end
        end

        def delete_relationships_from_global_registry_async(*types)
          types = types.empty? ? self.class.global_registry_relationship_types : types
          types.each do |type|
            next unless global_registry_relationship(type).id_value?
            ::GlobalRegistry::Bindings::Workers::DeleteEntityWorker.perform_async(
              global_registry_relationship(type).id_value
            )
          end
        end

        protected

        def global_registry_relationship_async_push(type)
          ::GlobalRegistry::Bindings::Workers::PushRelationshipWorker.perform_async(self.class, id, type)
        end

        def global_registry_relationship_async_replace(type)
          # Replace deletes GR relationship immediately before scheduling an async update
          ::GlobalRegistry::Bindings::Workers::DeleteEntityWorker.new.perform(
            global_registry_relationship(type).id_value
          )
          ::GlobalRegistry::Bindings::Workers::PushRelationshipWorker.perform_async(self.class, id, type)
        end

        def global_registry_relationship_async_delete(type)
          delete_relationships_from_global_registry_async(type)
        end

        def global_registry_relationship_async_ignore(_type); end # noop

        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/AbcSize
        def global_registry_relationship_change_action(type)
          [global_registry_relationship(type).primary_association_foreign_key,
           global_registry_relationship(type).related_association_foreign_key].each do |key|
            if previous_changes.key?(key)
              # Delete if changed from anything to nil
              return :delete if previous_changes[key].last.nil?
              # Replace if value changed
              return :replace if previous_changes[key].first != previous_changes[key].last &&
                                 !previous_changes[key].first.nil?
            elsif key.present? && send(key).nil?
              # Ignore if value didn't change and foreign_key is nil
              return :ignore
            end
          end
          # otherwise Create/Update
          :push
        end
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
