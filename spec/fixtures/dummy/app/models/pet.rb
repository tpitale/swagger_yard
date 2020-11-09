#
# This is the Pet model.
#
# @model
#
# @property id(required)        [integer]             the identifier for the pet
# @property names               [Array<string>]       the names for the pet
# @example names
#   ["Bob", "Bobo", "Bobby"]
# @property age                 [integer]             the age of the pet
# @example age
#   8
# @property relatives(required) [Array<AnimalThing>]  other Pets in its family
# @property birthday            [date]                the pet's birthday
# @example birthday
#   "2018/10/31T00:00:00.000Z"
# @property secret_name(x-internal:true) [string]          the pet's secret name
#
class Pet
end


module Pets
  # A dog model.
  # @model
  # @inherits Pet
  class Dog
  end

  # Not a swagger documented model.
  class Domo
  end
end
