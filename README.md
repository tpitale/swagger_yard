# SwaggerYard [![Build Status](https://travis-ci.org/livingsocial/swagger_yard.svg?branch=master)](https://travis-ci.org/livingsocial/swagger_yard) #

SwaggerYard is a gem to convert custom YARD tags in comments into Swagger 2.0 or OpenAPI 3.0.0 specs.

## Installation ##

Put SwaggerYard in your Gemfile:

    gem 'swagger_yard'

Install the gem with Bunder:

    bundle install


## Getting Started ##

Place configuration in a Rails initializer or suitable configuration file:

    # config/initializers/swagger_yard.rb
    SwaggerYard.configure do |config|
      config.api_version = "1.0"

      config.title = 'Your API'
      config.description = 'Your API does this'

      # where your actual api is hosted from
      config.api_base_path = "http://localhost:3000/api"

      # Where to find controllers (can be an array of paths/globs)
      config.controller_path = ::Rails.root + 'app/controllers/**/*'

      # Where to find models (can be an array)
      config.model_path = ::Rails.root + 'app/decorators/**/*'
    end

Then start to annotate controllers and models as described below.

### Generate Specification ###

To generate a Swagger or OpenAPI specification, use one of the `SwaggerYard::Swagger` or `SwaggerYard::OpenAPI` classes as follows in a script or Rake task (or use [swagger_yard-rails](/livingsocial/swagger_yard-rails)):

```
spec = SwaggerYard::OpenAPI.new
# Generate YAML
File.open("openapi.yml", "w") { |f| f << YAML.dump(spec.to_h) }
# Generate JSON
File.open("openapi.json, "w") { |f| f << JSON.pretty_generate(spec.to_h) }
```

## Documenting APIs

Documenting controllers and models is best illustrated by example.

### Controller ###

Each Swagger-ized controller must have a `@resource` tag naming the API to be documented. Without this tag, no endpoints will be generated.

Then, document each controller action method that is an endpoint of the API. Each endpoint needs to have a `@path` tag at a minimum. `@parameter` tags and `@response_type`/`@response` tags specify the inputs and outputs to the endpoint. A request body is specified with the use of a single `@parameter` tag with a `(body)` option.

```ruby
# @resource Account ownership
#
# This document describes the API for creating, reading, and deleting account ownerships.
#
class Accounts::OwnershipsController < ActionController::Base
  ##
  # Returns a list of ownerships associated with the account.
  #
  # Status can be -1(Deleted), 0(Inactive), 1(Active), 2(Expired) and 3(Cancelled).
  #
  # @path [GET] /accounts/ownerships
  #
  # @parameter offset   [integer]               Used for pagination of response data (default: 25 items per response). Specifies the offset of the next block of data to receive.
  # @parameter status   [array<string>]         Filter by status. (e.g. status[]=1&status[]=2&status[]=3).
  # @parameter sort_order [enum<id,begin_at,end_at,created_at>]  Orders response by fields. (e.g. sort_order=created_at).
  # @parameter sort_descending    [boolean]     Reverse order of sort_order sorting, make it descending.
  # @parameter begin_at_greater   [date]        Filters response to include only items with begin_at >= specified timestamp (e.g. begin_at_greater=2012-02-15T02:06:56Z).
  # @parameter begin_at_less      [date]        Filters response to include only items with begin_at <= specified timestamp (e.g. begin_at_less=2012-02-15T02:06:56Z).
  # @parameter end_at_greater     [date]        Filters response to include only items with end_at >= specified timestamp (e.g. end_at_greater=2012-02-15T02:06:56Z).
  # @parameter end_at_less        [date]        Filters response to include only items with end_at <= specified timestamp (e.g. end_at_less=2012-02-15T02:06:56Z).
  #
  def index
  end

  ##
  # Returns an ownership for an account by id
  #
  # @path [GET] /accounts/ownerships/{id}
  # @response_type [Ownership]
  # @error_message [EmptyOwnership] 404 Ownership not found
  # @error_message 400 Invalid ID supplied
  #
  def show
  end

  ##
  # Creates an ownership for an account
  #
  # @path [POST] /accounts/ownerships
  # @parameter ownership(body) [Ownership] The ownership to be created
  # @response_type [Ownership]
  def create
  end
end
```

### Model ###

Each model to be exposed in the specification must have a `@model` tag. Model properties are specified with `@property` tags.

```ruby
#
# @model
#
# @property id(required)    [integer]   the identifier for the pet
# @property name  [Array<string>]    the names for the pet
# @property age   [integer]   the age of the pet
# @property relatives(required) [Array<Pet>] other Pets in its family
#
class Pet
end
```

To then use your `Model` in your `Controller` documentation, add `@parameter`s:

```ruby
# @parameter pet(body) [Pet] The pet object
```

To support Swagger Polymorphism, use `@discriminator` and `@inherits`:

```ruby
#
# @model
#
# @property id(required)    [integer]   the identifier for the pet
# @property name  [Array<string>]    the names for the pet
# @property age   [integer]   the age of the pet
# @property relatives(required) [Array<Pet>] other Pets in its family
# @discriminator petType(required) [string] the type of pet
#
class Pet
end

#
# @model
#
# @inherits Pet
#
# @property packSize(required) [integer] the size of the pack the dog is from
#
class Dog < Pet
end
```

If you wish to name your model differently from the underlying ruby class, add the name as text to the `@model` tag. In the example here, if we did not specify `Dog` as the model name, it would have been named `Models_Dog`.

```ruby
# @model Dog
module Models
  class Dog
  end
end
```

### Types ###

Types of things (parameters or responses of an operation, properties of a model) are indicated inside square-brackets (e.g., `[string]`) as part of a YARD tag.

- Model references should be Capitalized or CamelCased by convention.
- Basic types (integer, boolean, string, object, number, date, time, date-time, uuid, etc.) should be lowercased.
- An array of models or basic types is specified with `[array<...>]`.
- An enum of allowed string values is specified with `[enum<one,two,three>]`.
- An object definition can include the property definitions of its fields, and / or of an additional property for any remaining allowed fields. E.g., `[object<name: string, age: integer,  string >]`
- Structured data like objects, arrays, pairs, etc., definitions can also be nested; E.g., `[object<pairs:array<object<right:integer,left:integer>>>]`
- JSON-Schema `format` attributes can be specified for basic types using `<...>`. For example, `[integer<int64>]` produces JSON `{ "type": "integer", "format": "int64" }`.
- Regex pattern constraints can be specified for strings using `[regex<PATTERN>]`. For example, `[regex<^.{3}$>]` produces JSON `{ "type": "string", "pattern": "^.{3}$" }`.

### Options ###

Parameter or property _options_ are expressed inside parenthesis immediately
following the parameter or property name.

Examples:

    # @parameter name(required) [string]  Name of the package
    # @parameter age(nullable)  [integer] Age of package
    # @parameter package(body)  [Package] Package object

Possible parameters include:

- `required`: indicates a required parameter or property.
- `nullable`: indicates that JSON `null` is an allowed value for the property.
- `multiple`: indicates a parameter may appear multiple times (usually in a
  query string, e.g., `param=a&param=b&param=c`)
- `body`/`query`/`path`/`formData`: Indicates where the parameter is located.

### External Schema ###

Types can be specified that refer to external JSON schema documents for their definition. External schema documents are expected to also define their models under a `definitions` top-level key like so:
```
{
  "definitions": {
    "MyStandardModel": {
    }
  }
}
```

To register an external schema so that it can be referenced in places where you specify a type, configure SwaggerYard as follows:
```ruby
SwaggerYard.configure do |config|
  config.external_schema mymodels: 'https://example.com/mymodels/v1.0'
end
```

Then refer to models in the schema using the syntax `[mymodels#MyStandardModel]` where types are specified. This causes SwaggerYard to emit the following schema for the type:

```
{ "$ref": "https://example.com/mymodels/v1.0#/definitions/MyStandardModel" }
```


## Authorization ##

### API Key auth ###

SwaggerYard supports API Key auth descriptions. Start by adding `@authorization` to your `ApplicationController`.

```ruby
#
# @authorization [api_key] header X-APPLICATION-API-KEY
#
class ApplicationController < ActionController::Base
end
```

Then you can use these authorizations from your controller or actions in a controller. The name comes from either header or query plus the name of the key downcased/underscored.

```ruby
#
# @authorize_with header_x_application_api_key
#
class PetController < ApplicationController
end
```

### Other security schemes (OAuth2) ###

Additionally SwaggerYard also supports custom [security schemes](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#security-scheme-object). You can define these in your configuration like:

```ruby
SwaggerYard.configure do |config|
  config.security_definitions['petstore_oauth'] = {
    type: "oauth2",
    flows: {
      implicit: {
        authorizationUrl: "http://swagger.io/api/oauth/dialog",
        scopes: {
          "write:pets": "modify pets in your account",
          "read:pets": "read your pets"		
        }
      }
    }
  }
end
```

Then you can also use these authorizations from your controller or actions in a controller.

```ruby
# @authorize_with petstore_oauth
class PetController < ApplicationController
end
```

## UI ##

We suggest using something like [swagger-ui_rails](https://github.com/3scale/swagger-ui_rails/tree/dev-2.1.3) for your UI needs inside of Rails.

To generate JSON from your code on request, checkout the [swagger_yard-rails](https://github.com/livingsocial/swagger_yard-rails) project. This provides an engine to parse and render the json required for use by swagger-ui_rails.

## More Information ##

* [swagger-ui_rails](https://github.com/3scale/swagger-ui_rails/tree/dev-2.1.3)
* [swagger_yard-rails](https://github.com/livingsocial/swagger_yard-rails)
* [Swagger-spec version 2.0](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md)
* [OpenAPI version 3.0.0](https://swagger.io/docs/specification/about/)
* [Yard](https://github.com/lsegal/yard)


### Path Discovery Function ##

SwaggerYard configuration allows setting of a "path discovery function" which
will be called for controller action method documentation that have no `@path`
tag. The function should return an array containing `["<method>", "<path>"]` if
any can be determined.

```ruby
SwaggerYard.configure do |config|
  config.path_discovery_function = ->(yard_obj) do
    # code here to inspect the yard doc object
    # and return a [method, path] for the api
  end
end
```

In [swagger_yard-rails][], this hook is used to set a function that inspects the
Rails routing tables to reverse look up and compute paths.

[swagger_yard-rails]: https://github.com/livingsocial/swagger_yard-rails
