# frozen_string_literal: true

class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  helper_method :current_user, :user_signed_in?

  private

    def current_user
      return unless session[:user_id]
      @current_user ||= User.find(session[:user_id])
    end

    def user_signed_in?
      current_user.present?
    end

    def require_oauth_user!
      return if current_user&.provider.present?
      redirect_to(current_user ? home_path : root_path, alert: 'SNSログインが必要です')
    end
end
