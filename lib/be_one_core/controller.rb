module BeOneCore
  module Controller
    extend ActiveSupport::Concern
    included do
      protected

      def render_as_json( val )
        RequestStore.store[:response_body] = val
        render json: val
      end

      def process_and_respond!(operation:, with_redirect_back: false, show_404: false, disallow_access: false)

        if disallow_access
          respond_to do |format|
            format.html {
              flash[:message] = I18n.t("common.to_use_need_login")
              flash[:error] = :restricted
              if with_redirect_back
                redirect_back fallback_location: root_path
              end
              if show_404
                raise ActionController::RoutingError.new('Not Found')
              end
            }
            response = {success: false, error: :restricted, message: I18n.t("common.to_use_need_login") }
            RequestStore.store[:response_body] = response
            format.json { render json: response }
          end
        else
          if result = operation.process
            yield operation, result
          else
            error = Array.wrap(operation.errors.values[0]).flatten[0]
            error_key = Array.wrap(operation.errors.keys[0]).flatten[0]
            respond_to do |format|
              format.html {
                flash[:message] = error
                flash[:error] = error_key
                if with_redirect_back
                  redirect_back fallback_location: root_path
                end
                if show_404
                  raise ActionController::RoutingError.new('Not Found')
                end
              }
              response = {success: false, error: error_key, message: error }
              RequestStore.store[:response_body] = response
              format.json { render json: response }
            end
          end
        end

      end

    end
  end
end
# details={:first_name=>[{:error=>:blank}], :last_name=>[{:error=>:blank}]
