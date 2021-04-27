# @resource SemiPrivate
class SemiPrivateController
  # @path [GET] /semi_private_public
  def index
  end

  # @path [GET] /semi_private
  # @visibility private
  def index_private
  end
end
