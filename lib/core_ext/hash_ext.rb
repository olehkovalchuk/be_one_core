module HashExt
  refine Hash do
    def except_nested_key(key)
      dup.except_nested_key!(key)
    end

    def except_nested_key!(key)
      each{ |k, v| v.delete(key) if v.is_a? Hash }
      self
    end
  end
end
