# @resource Pet
# @resource_path /pets
#
# This document describes the API for interacting with Pet resources
#
# @authorize_with header_x_application_api_key
#
class PetsController < ApplicationController
  # return a list of Pets
  # @path [GET] /pets
  # @response_type [Array<Pet>]
  # @parameter client_name(required) [string] The name of the client using the API
  def index
  end

  # return a Pet
  # @path [GET] /pets/{id}
  # @parameter id [integer] The ID for the Pet
  # @response_type [Pet]
  # @error_message [EmptyPet] 404 Pet not found
  # @error_message 400 Invalid ID supplied
  def show
  end

  # create a Pet
  # @path [POST] /pets
  # @parameter pet(required,body) [Pet] The pet object
  def create
  end

  # def update
  # end

  # def destroy
  # end
end
