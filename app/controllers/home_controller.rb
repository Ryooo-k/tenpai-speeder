# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @game_modes = GameMode.order(:created_at)
  end
end
