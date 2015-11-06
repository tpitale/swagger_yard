# @resource Transport
#
# This document describes the API for interacting with Transport resources
#
# @authorize_with header_x_application_api_key
#
class TransportsController < ApplicationController
  # return a list of Transports
  # @path [GET] /transports
  # @parameter sort [enum<id,wheels>]  Transports response sort order. (e.g. sort=id).
  # @response_type [Array<Transport>]
  def index
  end
end
