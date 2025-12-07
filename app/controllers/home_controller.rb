# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @game_modes = GameMode.all
    @game_modes_by_type = @game_modes.group_by(&:mode_type)
  end
end
