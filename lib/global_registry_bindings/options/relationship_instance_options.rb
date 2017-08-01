# frozen_string_literal: true

module GlobalRegistry #:nodoc:
  module Bindings #:nodoc:
    module Options
      class RelationshipInstanceOptions
        delegate :id_column,
                 :push_on,
                 :primary_binding,
                 :primary_association,
                 :primary_association_class,
                 :primary_association_foreign_key,
                 :related_association,
                 :related_association_class,
                 :related_association_foreign_key,
                 :ensure_relationship_type?,
                 :rename_entity_type?,
                 to: :@class_options

        def initialize(type, model)
          @model = model
          @class_options = model.class.global_registry_relationship(type)
        end

        def id_value
          @model.send id_column
        end

        def id_value=(value)
          @model.send "#{id_column}=", value
        end

        def id_value?
          @model.send "#{id_column}?"
        end

        def type
          t = @class_options.type
          t.is_a?(Proc) ? t.call(@model) : t
        end

        def client_integration_id
          option = @class_options.client_integration_id
          case option
          when Proc
            option.call(@model)
          when Symbol
            @model.send(option, type)
          end
        rescue ArgumentError
          @model.send(option)
        end

        def primary
          return @model.send(primary_association) if primary_association.present?
          @model
        end

        def primary_class
          primary_association_class || primary.class
        end

        def primary_type
          case primary_binding
          when :entity
            primary&.global_registry_entity&.type
          else
            primary&.global_registry_relationship(primary_binding)&.type
          end
        end

        def primary_id_value
          case primary_binding
          when :entity
            primary&.global_registry_entity&.id_value
          else
            primary&.global_registry_relationship(primary_binding)&.id_value
          end
        end

        def primary_class_is_self?
          primary_class == @model.class
        end

        def primary_relationship_name
          @class_options.primary_relationship_name || primary_type
        end

        def related
          @model.send(related_association) if related_association.present?
        end

        def related_type
          @class_options.related_association_type || related&.global_registry_entity&.type
        end

        def related_id_value
          option = @class_options.related_global_registry_id
          case option
          when Proc
            option.call(@model, type)
          when Symbol
            @model.send(option, type)
          else
            related&.global_registry_entity&.id_value
          end
        end

        def related_relationship_name
          @class_options.related_relationship_name || related_type
        end

        def exclude_fields
          option = @class_options.exclude_fields
          case option
          when Proc
            option.call(type, @model)
          when Symbol
            @model.send(option, type)
          else
            option
          end
        end

        def extra_fields
          option = @class_options.extra_fields
          case option
          when Proc
            option.call(type, @model)
          when Symbol
            @model.send(option, type)
          else
            option
          end
        end
      end
    end
  end
end
