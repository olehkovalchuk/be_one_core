module Operation
  module Crud
    module Update
      include Base

      def perform
        with_transaction do
          nested = {}
          attachmets = {}

          @old_model = @model.dup
          trigger :before_assign, @model, form
          form.attributes.slice(*params.keys.map(&:to_sym)).each_pair do |_attr,val|
            next if [:caching,:decorator, :can_moderate, :captcha].include?(_attr) || !model.respond_to?(_attr)
            begin
              if model.send(_attr).respond_to?(:attach)
                attachmets[_attr] = val if val.presence
              else
                model.send("#{_attr}=",val)
              end
          #    model.write_attribute _attr, val
            rescue ActiveModel::MissingAttributeError => e
              if _attr.to_s.end_with? "_attributes"
                nested[_attr] = val
                next
              end
            end
          end

          trigger :before_update, @model, form
          trigger :before_save, @model, form

          result = @model.save
          attachmets.each_pair do |k,v|
            add_attach(k,v)
          end

          if nested.any?
            nested.each_pair do |key, _attrs|
              key = key.to_s.sub("_attributes","")
              if key.singularize == key
                @model.send(key).update_attributes(_attrs)
              end

            end
          end
          trigger :after_save, @model, form
          trigger :after_update, @model, form
          trigger :after_assign, @old_model, @model, form

          result
        end
      end

      def setup!
        @model = find_by_id
        if model
          @params = model.attributes.merge(params)
        end
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
