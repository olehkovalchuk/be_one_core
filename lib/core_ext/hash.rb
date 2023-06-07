class Hash
  alias :read_attribute_for_serialization :[]
  def method_missing method
    if self.key? method
      self[method]
    else
      super
    end
  end
end