module Kernel
  alias_method :require_with_binding_of_caller, :require

  def require(feature)
    raise LoadError if feature == "binding_of_caller"

    require_with_binding_of_caller(feature)
  end
end
