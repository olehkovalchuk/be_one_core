module Operation
  module Crud
    module Exel
      include Base
      attr_reader :file_title
      def perform
        @file_title = "#{self.class.model_klass.name.underscore.gsub("/","_")}_report"
        spreadsheet = StringIO.new
        book = "#{self.class.model_klass.name}Report".constantize.new(@model.map(&:presenter)).to_xls
        book.write spreadsheet
        spreadsheet.string
      end

      def setup!
        @model = Finder.new(self.class.model_klass, params).get
      end
    end
  end
end
