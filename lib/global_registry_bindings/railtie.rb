# frozen_string_literal: true

module GlobalRegistry #:nodoc:
  module Bindings #:nodoc:
    class Railtie < Rails::Railtie
      config.after_initialize do
        if Module.const_defined? :Rollbar
          ::Rollbar.configure do |config|
            config.exception_level_filters.merge!(
              'GlobalRegistry::Bindings::RecordMissingGlobalRegistryId' => 'ignore',
              'GlobalRegistry::Bindings::EntityMissingMdmId' => 'ignore',
              'GlobalRegistry::Bindings::RelatedEntityMissingGlobalRegistryId' => 'ignore',
              'GlobalRegistry::Bindings::ParentEntityMissingGlobalRegistryId' => 'ignore'
            )
          end
        end
      end
    end
  end
end
