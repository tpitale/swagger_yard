# SwaggerYard [![Build Status](https://travis-ci.org/tpitale/swagger_yard.svg?branch=master)](https://travis-ci.org/tpitale/swagger_yard) #

SwaggerYard is a gem to convert extended YARD syntax comments into the swagger spec compliant json format.

## Installation ##

Put SwaggerYard in your Gemfile:

    gem 'swagger_yard'

Install the gem with Bunder:

    bundle install


## Getting Started ##

### Place configuration in a rails initializer ###

    # config/initializers/swagger_yard.rb
    SwaggerYard.configure do |config|
      config.api_version = "1.0"
      config.reload = Rails.env.development?

      # where your actual api is hosted from
      config.api_base_path = "http://localhost:3000/api"
    end

## SwaggerYard Usage ##

### Types ###

Types of things (parameters or responses of an operation, properties of a model)
are indicated inside square-brackets (e.g., `[string]`) as part of a YARD tag.

- Model references should be Capitalized or CamelCased by convention.
- Basic types (integer, boolean, string, object, number, date, time, date-time,
  uuid, etc.) should be lowercased.
- An array of models or basic types is specified with `[array<...>]`.
- An enum of allowed string values is specified with `[enum<one,two,three>]`.
- JSON-Schema `format` attributes can be specified for basic types using
  `<...>`. For example, `[integer<int64>]` produces JSON
  `{ "type": "integer", "format": "int64" }`.
- Regex pattern constraints can be specified for strings using
  `[regex<PATTERN>]`. For example, `[regex<^.{3}$>]` produces JSON
  `{ "type": "string", "pattern": "^.{3}$" }`.

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

### Example of using SwaggerYard in a Controller ###

```ruby
# @resource Account ownership
#
# @resource_path /accounts/ownerships
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
    ...
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
    ...
  end
end
```

### Example of using SwaggerYard in a Model ###

```ruby
#
# @model Pet
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

## Authorization ##

Currently, SwaggerYard only supports API Key auth descriptions. Start by adding `@authorization` to your `ApplicationController`.

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

## UI ##

We suggest using something like [swagger-ui_rails](https://github.com/3scale/swagger-ui_rails/tree/dev-2.1.3) for your UI needs inside of Rails.

To generate JSON from your code on request, checkout the [swagger_yard-rails](https://github.com/tpitale/swagger_yard-rails) project. This provides an engine to parse and render the json required for use by swagger-ui_rails.

## More Information ##

* [swagger-ui_rails](https://github.com/3scale/swagger-ui_rails/tree/dev-2.1.3)
* [swagger_yard-rails](https://github.com/tpitale/swagger_yard-rails)
* [Swagger-spec version 2.0](https://github.com/wordnik/swagger-spec/blob/master/versions/2.0.md)
* [Yard](https://github.com/lsegal/yard)

## Current Parsing "Tree" Structure ##

```
ResourceListing
|
-> ApiDeclaration (controller)
| |
| -> ListingInfo (controller class)
| -> Authorization (header/param for auth, also added to ResourceListing?)
| -> Api(s) (controller action, by path)
|   |
|   -> Operation(s) (controller action with HTTP method)
|     |
|     -> Parameter(s) (action param)
| 
-> Model (model)
  |
  -> Properties (model attributes)
```

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

[swagger_yard-rails]: https://github.com/tpitale/swagger_yard-rails
