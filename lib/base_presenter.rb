class BasePresenter
  attr_reader :object

  def presenter
    self
  end

  def initialize(object)
    @object = object
  end

  def method_missing(method, *args, &block)
    if object.respond_to?(method)
      object.send(method, *args, &block)
    else
      super
    end
  end
end