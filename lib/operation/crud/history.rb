module Operation
  module Crud
    module History
      include Base

      def perform
        raise NotImplementedError, "#{@model.class.name} hasn't versions" unless @model.respond_to?(:versions)
        total = @model.versions.count
        items = with_caching { @model.versions.offset(params[:start]).limit(params[:limit]).all }
        { total: @total, items:  }
      end
    end
  end
end
