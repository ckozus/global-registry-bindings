# Global Registry Bindings

Global Registry Bindings are a set of bindings to push ActiveRecord models to the Global Registry.


## Installation

Add to your Gemfile:
```ruby
gem 'global-registry-bindings'
```

Add a Global Registry initializer.
`config/initializers/global_registry.rb`
```ruby
require 'global_registry'
require 'global_registry_bindings'
GlobalRegistry.configure do |config|
  config.access_token = ENV['GLOBAL_REGISTRY_TOKEN'] || 'fake'
  config.base_url = ENV['GLOBAL_REGISTRY_URL'] || 'https://backend.global-registry.org'
end
```

Make sure sidekiq is configured. See [Using Redis](https://github.com/mperham/sidekiq/wiki/Using-Redis) for information.

## Usage

To make use of `global-registry-bindings` your model will need a few additional columns.
To push models to Global Registry, you will need a `global_registry_id` column. You additionally need a
`global_registry_mdm_id` to pull a Global Registry MDM (master data model) id. Additionally, relationships will also
require columns to track relationship ids. These columns should be of type 
`:string` or `:uuid` and allow null values. Column names are customizable through options.
```ruby
class CreatePeople < ActiveRecord::Migration
  def change
    add_column :people, :global_registry_id, :string, null: true, default: nil
    add_column :people, :global_registry_mdm_id, :string, null: true, default: nil
  end
end
```

Enable `global-registry-bindings` functionality by declaring `global_registry_bindings` on your model.
```ruby
class Person < ActiveRecord::Base
  global_registry_bindings mdm_id_column: :global_registry_mdm_id
end
```

## Options

You can pass various options to the `global_registry_bindings` method. Options will list whether they are valid for
`:entity`, `:relationship` or both bindings. 

* `:binding`: Type of Global Registry binding. Either `:entity` or `:relationship`.
(default: `:entity`)

* `:id_column`: Column used to track the Global Registry ID for the entity or relationship entity.
Can be a `:string` or `:uuid` column. (default: `:global_registry_id`) **[`:entity`, `:relationship`]**

* `:type`: Global Registry Entity Type name. This name should be unique in Global Registry or point to an existing
Entity Type.  When used in a `:relationship` binding, it is required to be unique across all relationships on this
ActiveRecord class. Accepts a Symbol or a Proc. Symbol is the name of the Entity Type, Proc
is passed the model instance and must return a symbol which is the Entity Type. Defaults to the underscored
name of the class. Ex: ```type: proc { |model| model.name.to_sym }```. **[`:entity`, `:relationship`]**

* `:push_on`: Array of Active Record lifecycle events used to push changes to Global Registry.
(default: `[:create, :update, :destroy]`) **[`:entity`]**

* `:parent`: Name of the Active Record parent association (`:belongs_to`, `:has_one` ...). Must be defined
before calling `global_registry_bindings` in order to determine foreign_key for use in exclude. Used to create a
hierarchy or to push child entity types. (Ex: person -> address) (default: `nil`) **[`:entity`]**

* `:parent_class`: Active Record Class name of the parent. Required if `:parent` can not be used
to determine the parent class. This can happen if parent is defined by another gem, like `ancestry`.
(default: `nil`) **[`:entity`]**

* `:primary_binding`: Determines what type of global-registry-binding the primary association points to. Defaults
to `:entity`, but can be set to a `:relationship` type (ex: `:assignment`) to create a relationship_type
between a relationship and an entity. (default: `:entity`) **[`:relationship`]**

* `:primary`: Name of the Active Record primary association. Must be defined before calling
global_registry_bindings in order to determine foreign_key for use in exclude. If missing, `:primary` is assumed to be
the current Active Record model. (default: `nil`) **[`:relationship`]**

* `:primary_class`: Class name of the primary model. Required if `:primary` can not be
used to determine the primary class. This can happen if parent is defined by another gem, like `ancestry`.
(default: `self.class`) **[`:relationship`]**

* `:primary_foreign_key`: Foreign Key column for the primary association. Used if foreign_key can
not be determined from `:primary`. (default: `:primary.foreign_key`) **[`:relationship`]**

* `:primary_name`: **Required** Name of primary relationship (Global Registry relationship1). Should be unique
to prevent ambiguous relationship names. (default: `nil`) **[`:relationship`]**

* `:related`: Name of the Active Record related association. Active Record association must be
defined before calling global_registry_bindings in order to determine the foreign key.
(default: `nil`) **[`:relationship`]**

* `:related_class`: Class name of the related model. Required if `:related_association` can not be
used to determine the related class. (default: `nil`) **[`:relationship`]**

* `:related_foreign_key`: Foreign Key column for the related association. Used if foreign_key can
not be determined from `:related`. (default: `:related.foreign_key`) **[`:relationship`]**

* `:related_name`: **Required** Name of the related relationship (Global Registry relationship2). Should be
unique to prevent ambiguous relationship names (default: `nil`) **[`:relationship`]**

* `:related_type`: Name of the related association Entity Type. Required if unable to determined
`:type` from related. (default: `nil`) **[`:relationship`]**

* `:related_global_registry_id`: Global Registry ID of a remote related entity. Proc or Symbol. Implementation
should cache this as it may be requested multiple times. (default: `nil`) **[`:relationship`]**

* `:ensure_type`: Ensure Global Registry Entity Type or Relationship Entity Type exists and is up to date.
(default: `true`) **[`:entity`, `:relationship`]**

* `:client_integration_id`: Client Integration ID for relationship. Proc or Symbol.
(default: `:primary.id`) **[`:relationship`]**

* `:include_all_columns`: Include all model columns in the fields to push to Global Registry. If `false`, fields must
be defined in the `:fields` option. (default: `false`) **[`:entity`, `:relationship`]**

* `:exclude`: Array, Proc or Symbol. Array of Model fields (as symbols) to exclude when pushing to Global
Registry. Array Will additionally include `:mdm_id_column` and `:parent_association` foreign key when defined.
If Proc, is passed type and model instance and should return an Array of the fields to exclude. If Symbol,
this should be a method name the Model instance responds to. It is passed the type and should return an Array
of fields to exclude. When Proc or Symbol are used, you must explicitly return the standard defaults.
(default:  `[:id, :created_at, :updated_at, :global_registry_id]`) **[`:entity`, `:relationship`]**

* `:fields`: Additional fields to send to Global Registry. Hash, Proc or Symbol. As a Hash, names are the
keys and :type attributes are the values. Ex: `{language: :string}`. Name is a symbol and type is an
ActiveRecord column type. As a Proc, it is passed the type and model instance, and should return a Hash.
As a Symbol, the model should respond to this method, is passed the type, and should return a Hash.
**[`:entity`, `:relationship`]**

* `:mdm_id_column`: Column used to enable MDM tracking and set the name of the column. MDM is disabled when this
option is nil or empty. (default: `nil`) **[`:entity`]**

* `:mdm_timeout`: Only pull mdm information at most once every `:mdm_timeout`. (default: `1.minute`)
**[`:entity`]**

## Entities

`global-registry-bindings` default bindings is to push an Active Record class as an Entity to Global Registry.
This can be used to push root level entities, entities with a parent and entities with a hierarchy. You can also
enable fetching of a Master Data Model from Global Registry.

See [About Entities](https://github.com/CruGlobal/global_registry_docs/wiki/About-Entities) for more
information on Global Registry Entities.

### Root Entity
```ruby
class Person < ActiveRecord::Base
  global_registry_bindings mdm_id_column: :global_registry_mdm_id
end
```
This will push the Person Active Record model to Global Registry as a `person` Entity Type, storing the resulting id
value in the `global_registry_id` column, as well as fetching a `master_person` Entity and storing it in the
`global_registry_mdm_id` column.

### Parent/Child Entity
```ruby
class Person < ActiveRecord::Base
  has_many :addresses, inverse_of: :person
  global_registry_bindings
end
 
class Address < ActiveRecord::Base
  belongs_to :person
  global_registry_bindings
end
```
This will push the Person model to Global Registry as a `person` Entity Type, and the Address model as an `address`
Entity Type that has a parent of `person`.

### Entity Hierarchy
```ruby
class Ministry < ActiveRecord::Base
  has_many :children, class_name: 'Ministry', foreign_key: :parent_id
  belongs_to :parent, class_name: 'Ministry'
  
  global_registry_bindings parent: :parent
end
```
This will push the Ministry model to Global Registry as well as the parent/child hierarchy. Global Registry only allows
a single parent, and does not allow circular references. Hierarchy is also EntityType specific, and not saved per
system in Global Registry, meaning, the last system to push a parent wins (You can accidently override another systems
hierarchy. This should be avoided and instead pushed as a relationship if needed).

## Relationships

`global-registry-bindings` can also be configured to push relationships between models to Global Registry. All
relationships in Global Registry are many to many, but by using Active Record associations, we can simulate one to many
and one to one.

See [About Relationships](https://github.com/CruGlobal/global_registry_docs/wiki/About-Relationships) for more
information on Global Registry relationships.

### Many-to-Many with join model
```ruby
class Ministry < ActiveRecord::Base
  has_many :assignments
  has_many :people, through: :assignments
  global_registry_bindings
end
 
class Person < ActiveRecord::Base
  has_many :assignments
  has_many :ministries, through: :assignments
  global_registry_bindings
end
 
class Assignment < ActiveRecord::Base
  belongs_to :person
  belongs_to :ministry
  global_registry_bindings binding: :relationship,
                           primary: :person,
                           primary_name: :people,
                           related: :ministry,
                           related_name: :ministries
end
```
This will push Ministry and Person to Global Registry as Entities, and Assignment join model as a relationship between
them, storing the relationship id in the Assignment `global_registry_id` column.

### One-to-Many
```ruby
class Person < ActiveRecord::Base
  has_many :pets
  global_registry_bindings
end
 
class Pet < ActiveRecord::Base
  belongs_to :person
  global_registry_bindings binding: :relationship,
                           type: :owner,
                           related: :person
end
```
## Example Models

Example models can be found in the [specs](https://github.com/CruGlobal/global-registry-bindings/tree/master/spec/internal/app/models).
