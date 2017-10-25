module DeviseTokenAuth
  class ConfirmationsController < DeviseTokenAuth::ApplicationController
    def show
      @resource = resource_class.confirm_by_token(params[:confirmation_token])

      if @resource && @resource.id
        # create client id
        client_id  = SecureRandom.urlsafe_base64(nil, false)
        token      = SecureRandom.urlsafe_base64(nil, false)
        token_hash = BCrypt::Password.create(token)
        expiry     = (Time.now + @resource.token_lifespan).to_i

        @resource.tokens[client_id] = {
          token:  token_hash,
          expiry: expiry
        }

        sign_in(@resource)
        @resource.save!

        yield @resource if block_given?

        redirect_to(@resource.build_auth_url(params[:redirect_url], {
          DeviseTokenAuth.headers_names["access-token"] => token,
          DeviseTokenAuth.headers_names["client"] => client_id,

          :account_confirmation_success => true,
          :config => params[:config],

          # Legacy parameters which may be removed in a future release.
          # Consider using "client" and "access-token" in client code.
          # See: github.com/lynndylanhurley/devise_token_auth/issues/993
          :client_id => client_id,
          :token => token
        }))
      else
        raise ActionController::RoutingError.new('Not Found')
      end
    end
  end
end
