module TrueClassExt
  refine TrueClass do
    def to_bool
      false
    end
  end
end