# SwaggerYard Changelog #

## 0.3.2 -- 22-01-2016 ##

* Ensure only one parameter object for each declared name
* Mangle model names such that only alphanumeric and '_' are allowed
* Repository moved under `livingsocial` organization.

## 0.3.1 ##

* Use hashing functionality of YARD registry to avoid re-parsing files that
  haven't changed, improving performance for larger codebases.
* Deprecate `@resource_path` and remove `@status_code`
* Add more types and options (nullable, JSON Schema formats, regexes, uuid)

## 0.3.0 ##

* Add `config.path_discovery_function` to be able to hook in logic from
  swagger_yard-rails to compute paths from the router
* Allow `@resource_path` to be omitted in a controller class docstring.
  `@resource` is required in order to indicate that a controller is swaggered.
* Remove `@notes` tag. There is no convenient place for notes to be mapped to a
  swagger spec other than to be part of the API's description.
* Remove `@parameter_list` tag in favor of new `enum<val1,val2>` type. Parameter
  list usage was cumbersome and not well documented. This also enabled removal
  of the Parameter class `allowable_values` option, which was no longer used.
* Remove implicit, undocumented `format_type` parameter. If you still need a
  format (or `format_type`) parameter, use the new `enum` type. Example:

    ```
	# @path /hello.{format}
    # @parameter format [enum<json,xml>] Format of the response. One of JSON or XML.
    ```

* Deprecate `config.swagger_spec_base_path` and `config.api_path`. Not used anywhere.

## 0.2.0 -- 20-10-2015 ##

* Support for Swagger's Spec v2

    *Nick Sieger <@nicksieger>*

* Remove support for Spec v1

    *Tony Pitale <@tpitale>*

## 0.1.0 -- 15-10-2015 ##

* !REMOVE RAILS ENGINE AND UI!

    *Tony Pitale <@tpitale>*

## 0.0.7 ##

*   Allow deeply nested model objects

    *Peter Doree*

*   Adds support for Model and $ref
*   Add doc update for using Model
*   Fix failure when `app/controllers` had `module`s in it
*   Add specs

    *Tony Pitale*
