module Operation
  class Error < StandardError
    # TODO: use this shit
    attr_reader :errors
    def initialize(errors = {})
      @errors = errors
      super("Internal server error")
    end
  end
end
