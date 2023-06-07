module Journal
  class Error < StandardError
    attr_accessor :code, :message

    def initialize(code, message = false)
      @code = code
      @message = message || code
      super @message
    end
  end
end
