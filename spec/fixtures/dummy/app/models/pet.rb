#
# This is the Pet model.
#
# @model
#
# @property id(required)        [integer]             the identifier for the pet
# @property names               [Array<string>]       the names for the pet
# @property age                 [integer]             the age of the pet
# @property relatives(required) [Array<AnimalThing>]  other Pets in its family
# @property birthday            [date]                the pet's birthday
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
