module Api
  class SessionsController < ApplicationController
    before_action :authorize_access_request!, except: [:cross, :google_auth]
    include SessionsHelper
    include ActionController::Cookies
    def google_auth
      # Get access tokens from the google server
      access_token = request.env["omniauth.auth"]
      user = User.create_from_omniauth(access_token)

      session[:user_id] = user.id
      # Access_token is used to authenticate request made from the rails application to the google server
      user.access_token = access_token.credentials.token
      # Refresh_token to request new access_token
      # Note: Refresh_token is only sent once during the first request
      refresh_token = access_token.credentials.refresh_token
      user.refresh_token = refresh_token if refresh_token.present?
      if user.save
        payload = {user_id: user.id}
        session = JWTSessions::Session.new(payload: payload, refresh_by_access_allowed: true)
        tokens = session.login
        @csrf = tokens[:csrf]
        response.set_cookie(JWTSessions.access_cookie,
                            value: tokens[:access],
                            secure: Rails.env.production?)

      end
      @token = access_token.credentials.token
      render "popup/login-google-popup.html.erb"
    end

    def destroy
      session = JWTSessions::Session.new(payload: payload)
      session.flush_by_access_payload
      render json: :ok
    end

    def is_authenticated
      render json: {
        :current_user => current_user
      }
    end

    def cross
      render "popup/login-google-popup.html.erb"
    end

    private

    def not_found
      render json: { error: 'Cannont find such email/password combination' }, status: :not_found
    end
  end
end
