# @resource Pet
# @resource_path /pets
# 
# This document describes the API for interacting with Pet resources
# 
class PetsController < ApplicationController
  # return a list of Pets
  # @path [GET] /pets.{format_type}
  def index
  end

  # return a Pet
  # @path [GET] /pets/{id}.{format_type}
  # @parameter [integer] id(required,body) The ID for the Pet
  def show
  end

  # create a Pet
  # @path [POST] /pets
  # @parameter [Pet] pet The pet object
  def create
  end

  # def update
  # end

  # def destroy
  # end
end
