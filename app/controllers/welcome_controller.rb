# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    @login_path = Rails.env.development? ? '/auth/developer' : '/auth/twitter'
  end
end
