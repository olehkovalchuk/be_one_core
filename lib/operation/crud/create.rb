module Operation
  module Crud
    module Create
      include Base

      def perform
        with_transaction do
          _attributes = form.attributes
          _attributes.delete(:caching)
          _attributes.delete(:decorator)
          _attributes.delete(:can_moderate)
          _attributes.delete(:captcha)
          pp _attributes
          attachmets = {}
          _attributes.each_pair do |_attr,val|
            next unless model.respond_to?(_attr)
            if model.send(_attr).respond_to?(:attach)
              attachmets[_attr] = _attributes.delete(_attr)
            else
              model.send("#{_attr}=",val)
            end
          end

          # model.attributes = _attributes
          trigger :before_create, @model, form
          trigger :before_save, @model, form

          result = @model.save

          attachmets.each_pair do |k,v|
            add_attach(k,v)
          end

          trigger :after_save, @model, form
          trigger :after_create, @model, form

          result
        end
      end

      def setup!
        @model = self.class.model_klass.new
      end

      private

      def add_attach(k,v)
        if v.kind_of?(Array)
          @model.send(k).attach(v.select{|f| f.kind_of?(ActionDispatch::Http::UploadedFile) })           
        else
          if v.kind_of?(ActionDispatch::Http::UploadedFile)
            @model.send(k).attach(v)
          elsif v.presence
            @model.send(k).attach(io: v["io"], filename: v["filename"], content_type: v["content_type"])
          end
        end
      end

    end
  end
end
