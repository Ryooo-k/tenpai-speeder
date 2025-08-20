# frozen_string_literal: true

class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  helper_method :current_user, :user_signed_in?

  private

    def authenticate_user!
      redirect_to root_path unless session[:user_id]
    end

    def current_user
      return unless session[:user_id]
      @current_user ||= User.find(session[:user_id])
    end

    def user_signed_in?
      current_user.present?
    end
end
