# SwaggerYard #

SwaggerYard is a gem to convert extended YARD syntax comments into the swagger spec compliant json format.

## Installation ##

Put SwaggerYard in your Gemfile:

    gem 'swagger_yard'

Install the gem with Bunder:

    bundle install


## Getting Started ##

### Place your configuration in a your rails initializers ###

    # config/initializers/swagger_yard.rb
    SwaggerYard.configure do |config|
      config.swagger_version = "1.2"
      config.api_version = "1.0"
      config.reload = Rails.env.development?

      # where your actual api is hosted from
      config.api_base_path = "http://localhost:3000/api"

      # where your swagger spec json will show up
      # configure this to match SwaggerYard::Rails mount point
      config.swagger_spec_base_path = "http://localhost:3000/swagger/api"
    end

    # register swagger tags with YARD
    SwaggerYard.register_custom_yard_tags!

## Example Documentation ##

### Here is an example of how to use SwaggerYard in your Controller ###

**Note:** Model references should be Capitalized or CamelCased, basic types (integer, boolean, string, etc) should be lowercased everywhere.

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
  # @notes Status can be -1(Deleted), 0(Inactive), 1(Active), 2(Expired) and 3(Cancelled).
  #
  # @path [GET] /accounts/ownerships.{format_type}
  #
  # @parameter offset   [integer]               Used for pagination of response data (default: 25 items per response). Specifies the offset of the next block of data to receive.
  # @parameter status   [array<string>]                 Filter by status. (e.g. status[]=1&status[]=2&status[]=3).
  # @parameter_list     [String]    sort_order        Orders response by fields. (e.g. sort_order=created_at).
  #                     [List]      id
  #                     [List]      begin_at
  #                     [List]      end_at
  #                     [List]      created_at
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
  # @path [GET] /accounts/ownerships/{id}.{format_type}
  # @response_type [Ownership]
  # @error_message [EmptyOwnership] 404 Ownership not found
  # @error_message 400 Invalid ID supplied
  #
  def show
    ...
  end
end
```

### Here is an example of how to use SwaggerYard in your Model ###

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
# @parameter [Pet] pet The pet object
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

* [Swagger-ui](https://github.com/wordnik/swagger-ui)
* [swagger-ui_rails](https://github.com/3scale/swagger-ui_rails/tree/dev-2.1.3)
* [Yard](https://github.com/lsegal/yard)
* [Swagger-spec version 1.2](https://github.com/wordnik/swagger-spec/blob/master/versions/1.2.md)
* [Swagger-spec version 2.0](https://github.com/wordnik/swagger-spec/blob/master/versions/2.0.md)
