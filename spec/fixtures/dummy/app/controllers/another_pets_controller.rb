# @resource Pet
#
# This document describes the API for interacting with Pet resources
#
# @authorize_with header_x_application_api_key
# @tag_group Test Tag Group
#
class AnotherPetsController < ApplicationController
  # boop a Pet
  # @path [GET] /pets/boop
  # @operation_id boopPet
  # @response 204
  def boop
  end
end
