module FalseClassExt
  refine FalseClass do
    def to_bool
      false
    end
  end
end