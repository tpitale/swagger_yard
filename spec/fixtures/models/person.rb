# @model Person
# @property [Person] parent
# @discriminator myType(required) [string]
class Person
  extend Forwardable

  # @property [string] (required)
  def_delegators :get_parent, :first_name, :last_name

  # @property [Address] the person's address
  def address
  end

  # @property [integer] (required) the person's age
  attr_reader :age

  # The person's country
  # @property [string]
  attr_accessor :country

  # This should not be included in the model
  # @property [integer]
  attr_writer :age

  def some_non_model_method
  end

  private
  def get_parent
  end
end
